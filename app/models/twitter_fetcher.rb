require 'json'

class TwitterFetcher < ActiveRecord::Base
  has_many :post_histories, :dependent => :destroy

  USER_AGENT = "youRoom twitter fetcher"
  URL_FORMAT = "http://twitter.com/%s/status/%s"
  @@twitter_ignore_errors = [Twitter::ServiceUnavailable, Twitter::NotFound, Twitter::Unauthorized].freeze

  attr_accessor :setting_type, :setting_value, :skip_fetching, :setting_exclude

  validates_presence_of :setting_type, :setting_value, :access_token, :access_token_secret

  serialize :setting_option

  def before_save
    if setting_type and setting_value
      self.setting_option = { :type => self.setting_type, :value => self.setting_value, :exclude => self.setting_exclude }
    end
  end

  def after_create
    unless skip_fetching
      self.fetch
      self.create_entries
    end
  end

  def self.fetch_all
    errors = []
    logger.info "AllCount: #{self.scoped({}).count}"
    active = self.scoped(:conditions => { :group_id => self.active_room_ids })
    logger.info "ActiveoCunt: #{active.count}"
    active.each do |tf|
      begin
        logger.info "[pid:#{Process.pid}] >> fetching #{tf.setting_option.inspect} #{tf.attributes.inspect}"
        items = tf.fetch
        logger.info "[pid:#{Process.pid}] >> items: #{items.size}"
        entries = tf.create_entries
        logger.info "[pid:#{Process.pid}] >> entries: #{entries.size}"
        logger.info "[pid:#{Process.pid}] >> finished #{tf.setting_option.inspect}"
      rescue => e
        errors << { :twitter_fetcher => tf, :error => e}
      end
    end
    logger.error "[pid:#{Process.pid}]-------------FetchAll Error------------"
    errors.each do |error|
      logger.error "TF: #{error[:twitter_fetcher].inspect}\nERROR: #{error[:error].inspect}"
      error[:error].backtrace.each{ |line| logger.error line }
      logger.error "-" * 20
    end
    logger.error "[pid:#{Process.pid}]-------------FetchAll Error------------"
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
          'entry[content]' => CGI.unescapeHTML(content),
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
    else
      logger.error "[POST Entry to youRoom] Failed to #{response}: #{response.body}"
      nil
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
    logger.info " >> type: #{self.setting_option[:type]}"
    @response =
      if type?(:keyword)
        search_client_by_twitter.fetch
      else
        client_by_twitter.user_timeline(self.setting_option[:value], since_query)
      end
  rescue => e
    unless @@twitter_ignore_errors.any? {|error| e.is_a?(error) }
      HoptoadNotifier.notify(e)
    end
  end

  def items
    return @items if defined?(@items)

    items = if @response.is_a?(Hash)
              @response["results"]
            elsif @response.is_a?(Array)
              @response
            end || []

    items = items.select{|item| !Regexp.new(self.setting_option[:exclude].split(',').map(&:strip).join('|')).match(item.text) } unless self.setting_option[:exclude].blank?

    @items = items
  end

  def clear_items
    @items = nil
  end

  def type?(type)
    type.to_s == self.setting_option[:type]
  end

  def since_query
    if since_id.blank?
      { :count => 5 }
    else
      { :since_id => self.since_id }
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
                         entry ? entry['id'] : nil
                       end
  end

  def parent_tweet_id tweet_id
    response = client_by_twitter.status(tweet_id)
    if response.is_a? Hash
      response.in_reply_to_status_id ||
        ((rs = response.retweeted_status) && rs.id)
    end
  end

  def access_token_as_youroom_bot
    self.class.access_token_as_youroom_bot
  end

  def self.active_room_ids
    res = JSON.parse(TwitterFetcher.access_token_as_youroom_bot.get('/groups/my.json').body)
    res.map{ |group| group["group"]["to_param"].to_i rescue nil }.compact
  rescue => e
    logger.error "[Failed to fetch youroom active room]"
    []
  end

  def self.access_token_as_youroom_bot
    @access_token_as_youroom_bot ||= OAuth::AccessToken.new(youroom_consumer, configatron.youroom.access_token.key, configatron.youroom.access_token.secret)
  end

  def self.youroom_consumer
    @youroom_consumer ||= OAuth::Consumer.new(configatron.youroom.consumer.key, configatron.youroom.consumer.secret, :site => Youroom.root_url)
  end

  def client_by_twitter
    @oauth_by_twitter ||= Twitter::Client.new(:oauth_token => self.access_token, :oauth_token_secret => self.access_token_secret)
  end

  def search_client_by_twitter
    @search_client_by_twitter ||= Twitter::Search.new
    @search_client_by_twitter.containing(self.setting_option[:value])
    if self.since_id
      @search_client_by_twitter.since_id(self.since_id)
    else
      @search_client_by_twitter.per_page(5)
    end
    @search_client_by_twitter
  end
end
