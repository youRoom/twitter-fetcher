require 'json'

class TwitterFetcher < ActiveRecord::Base
  has_many :post_histories

  USER_AGENT = "youRoom twitter fetcher"
  URL_FORMAT = "http://twitter.com/%s/status/%s"

  attr_accessor :setting_type, :setting_value

  validates_presence_of :setting_type, :setting_value, :access_token, :access_token_secret

  serialize :setting_option

  def before_save
    if setting_type and setting_value
      self.setting_option = { :type => self.setting_type, :value => self.setting_value }
    end
  end

  def after_create
    self.fetch
    self.create_entries
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
        response = post_entry(content, img_url, name, url, parent_id(tweet_id))
        case response
        when Net::HTTPCreated
          entry = JSON::parse(response.body)['entry']
          post_histories.create!(:entry_id => entry['id'], :tweet_id => tweet_id)
          entry
        end
      end.compact! || []
    end
  end

  def post_entry content, img_url, name, url, parent_id = nil
    response = access_token_as_youroom_bot.post "#{target_group_url}/entries.json", {
      'entry[content]' => content,
      'entry[parent_id]' => parent_id,
      'entry[attachment_attributes][data][user][img_url]' => img_url,
      'entry[attachment_attributes][data][user][name]' => name,
      'entry[attachment_attributes][data][url]' => url,
      'entry[attachment_attributes][attachment_type]' => 'twitter'
    }
  end

  def target_group_url
    self.class.youroom_group_url self.group_id
  end

  def self.youroom_group_url group_id
   "http://r#{group_id}.#{configatron.url_options[:host]}:#{configatron.url_options[:port]}"
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
    { :q => self.setting_option[:value] }
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

  private
  def access_token_as_youroom_bot
    @access_token_as_youroom_bot ||= OAuth::AccessToken.new(youroom_consumer, configatron.youroom.access_token.key, configatron.youroom.access_token.secret)
  end

  def youroom_consumer
    @youroom_consumer ||= OAuth::Consumer.new(configatron.youroom.consumer.key, configatron.youroom.consumer.secret, :site => "http://#{configatron.url_options[:host]}:#{configatron.url_options[:port]}")
  end

  def oauth_by_twitter
    @oauth_by_twitter ||= Twitter::OAuth.new(configatron.twitter.consumer.key, configatron.twitter.consumer.secret)
    @oauth_by_twitter.authorize_from_access(self.access_token, self.access_token_secret)
    @oauth_by_twitter
  end

  def client_by_twitter
    @client_by_twitter ||= Twitter::Base.new(oauth_by_twitter)
  end

  def parent_id tweet_id
    return nil unless tweet_id
    response = client_by_twitter.status(tweet_id)
    if response.is_a? Hash
      if in_reply_to_status_id = response.in_reply_to_status_id
        post_history = post_histories.find_by_tweet_id(in_reply_to_status_id)
        if post_history
          return post_history.entry_id
        end
      end
      if retweeted_status = response.retweeted_status
        post_history = post_histories.find_by_tweet_id(retweeted_status.id)
        if post_history
          return post_history.entry_id
        end
      end
    end
  end
end
