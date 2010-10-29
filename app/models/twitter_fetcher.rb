require 'json'

class TwitterFetcher < ActiveRecord::Base
  has_many :post_histories, :dependent => :destroy

  USER_AGENT = "youRoom twitter fetcher"
  URL_FORMAT = "http://twitter.com/%s/status/%s"

  attr_accessor :setting_type, :setting_value, :skip_fetching

  validates_presence_of :setting_type, :setting_value, :access_token, :access_token_secret

  serialize :setting_option

  def before_save
    if setting_type and setting_value
      self.setting_option = { :type => self.setting_type, :value => self.setting_value }
    end
  end

  def after_create
    unless skip_fetching
      self.fetch
      self.create_entries
    end
  end

  def self.fetch_all
    self.all.each do |tf|
      logger.info " >> fetching #{tf.setting_option.inspect} #{tf.attributes.inspect}"
      items = tf.fetch
      logger.info " >> items: #{items.size}"
      entries = tf.create_entries
      logger.info " >> entries: #{entries.size}"
      logger.info " >> finished #{tf.setting_option.inspect}"
    end
  ensure
    logger.flush
  end

  def fetch
    get
    unless items.blank?
      self.since_id = result_max_id
      self.save(false)
    end
    items
  end

  def create_entries
    ActiveRecord::Base.transaction do
      each_tweet do |content, img_url, name, url, tweet_id|
        body_hash = {
          'entry[content]' => content,
          'entry[parent_id]' => parent_topic_id(tweet_id),
          'entry[attachment_attributes][data][user][img_url]' => img_url,
          'entry[attachment_attributes][data][user][name]' => name,
          'entry[attachment_attributes][data][url]' => url,
          'entry[attachment_attributes][attachment_type]' => 'twitter'
        }
        post_entry body_hash, tweet_id
      end.compact! || []
    end
  end

  def post_entry body_hash, tweet_id = nil
    logger.info "[POST Entry to youRoom] #{target_group_url}: #{body_hash.inspect}"
    response = access_token_as_youroom_bot.post "#{target_group_url}/entries.json", body_hash
    case response
    when Net::HTTPCreated
      entry = JSON::parse(response.body)['entry']
      self.post_histories.create!(:entry_id => entry['id'], :tweet_id => tweet_id)
      entry
    end
  end

  def target_group_url
    self.class.youroom_group_url self.group_id
  end

  def self.youroom_group_url group_id
    Youroom.group_url group_id
  end

  def each_tweet(&block)
    items.reverse.map do |tweet|
      user = tweet["user"]
      img_url, screen_name, name = user ? [user["profile_image_url"], user["screen_name"], "#{user["screen_name"]} / #{user["name"]}"] : [tweet["profile_image_url"], tweet["from_user"], tweet["from_user"]]
      content = tweet["text"][/^.{0,140}/m]
      url = sprintf(URL_FORMAT, screen_name, tweet["id"])

      yield(content, img_url, name, url, tweet['id'])
    end
  end

  def get
    logger.info " >> url: #{url}"
    logger.info " >> query: #{query.inspect}"
    @response = Twitter::Request.get(oauth_by_twitter, url, :query => self.query, :format => :json, :headers => {'User-Agent' => USER_AGENT})
  end

  def items
    @items ||= if @response.is_a?(Hash)
                 @response["results"]
               elsif @response.is_a?(Array)
                 @response
               end || []
  end

  def clear_items
    @items = nil
  end

  def url
    if type?(:keyword)
      search_api_url
    else
      user_api_url
    end
  end

  def user
    self.setting_option[:value]
  end

  def user_api_url
    "http://twitter.com/statuses/user_timeline/#{self.user}.json"
  end

  def type?(type)
    type.to_s == self.setting_option[:type]
  end

  def search_query
    { :q => URI.encode(self.setting_option[:value]) }
  end

  def search_api_url
    'http://search.twitter.com/search.json'
  end

  def since_query
    if since_id.blank?
      if self.type?(:keyword)
        { :rpp => 5 }
      else
        { :count => 5 }
      end

    else
      { :since_id => self.since_id }
    end
  end

  def query
    if type?(:keyword)
      since_query.merge(search_query)
    else
      since_query
    end
  end

  def result_max_id
    if @response.is_a?(Hash)
      @response["max_id"]
    else
      @response.first["id"]
    end
  end

  def parent_topic_id tweet_id
    return self.root_topic_id unless tweet_id

    pt_id = self.parent_tweet_id(tweet_id)
    if post_history = (pt_id && self.post_histories.find_by_tweet_id(pt_id))
      post_history.entry_id
    else
      self.root_topic_id
    end
  end

  def root_topic_id
    @root_topic_id ||= if root_history = self.post_histories(true).created_at_gte(Time.now.beginning_of_day).ascend_by_created_at.tweet_id_null.first
                         root_history.entry_id
                       else
                         entry = post_entry('entry[content]' => "Twitter feeds of #{self.setting_option[:value]} on #{Time.now.strftime('%Y/%m/%d')}",
                                            'entry[attachment_attributes][attachment_type]' => 'twitter',
                                            'entry[attachment_attributes][data][render_default_view]' => true)
                         entry['id']
                       end
  end

  def parent_tweet_id tweet_id
    response = client_by_twitter.status(tweet_id)
    if response.is_a? Hash
      response.in_reply_to_status_id ||
        ((rs = response.retweeted_status) && rs.id)
    end
  end

  private
  def access_token_as_youroom_bot
    @access_token_as_youroom_bot ||= OAuth::AccessToken.new(youroom_consumer, configatron.youroom.access_token.key, configatron.youroom.access_token.secret)
  end

  def youroom_consumer
    @youroom_consumer ||= OAuth::Consumer.new(configatron.youroom.consumer.key, configatron.youroom.consumer.secret, :site => Youroom.root_url)
  end

  def oauth_by_twitter
    @oauth_by_twitter ||= Twitter::OAuth.new(configatron.twitter.consumer.key, configatron.twitter.consumer.secret)
    @oauth_by_twitter.authorize_from_access(self.access_token, self.access_token_secret)
    @oauth_by_twitter
  end

  def client_by_twitter
    @client_by_twitter ||= Twitter::Base.new(oauth_by_twitter)
  end

end
