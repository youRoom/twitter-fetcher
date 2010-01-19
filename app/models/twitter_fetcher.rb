require "httparty"
require 'oauth'
require 'json'

class TwitterFetcher < ActiveRecord::Base

#  @@fetch_user = User.find_by_email configatron.twitter_fetcher_email
#  cattr_reader :fetch_user
#
#  FETCH_USER_NAME = "TwitterFetcher"
  USER_AGENT = "youRoom twitter fetcher"
  URL_FORMAT = "http://twitter.com/%s/status/%s"
#
  attr_accessor :setting_type, :setting_value

  validates_presence_of :setting_type, :setting_value

  serialize :setting_option

  def before_save
    if setting_type and setting_value
      self.setting_option = { :type => self.setting_type, :value => self.setting_value }
    end
  end

  def after_create
#    if group
#      self.join_group
      self.fetch
      self.create_entries
#    end
  end
#
#  def after_destroy
#    leave_group
#  end
#
#  # TODO: UNJOINEDになった場合はUNJOINEDになったまま直した方が良いか?
#  def join_group
#    unless self.group.users.include?(self.class.fetch_user)
#      part = self.class.fetch_user.join(self.group, :active)
#      part.without_join_validation = true
#      part.build_profile_values_only_name = FETCH_USER_NAME
#      part.build_picture.fill_attr(fetch_user_picture)
#      part.save!
#    end
#    part
#  end
#
#  def leave_group
#    if group.twitter_fetchers(false).empty?
#      participation.be_leaved!
#    end
#  end
#
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
#
#  def setting_option_to_s
#    "[#{setting_option[:type]}: #{setting_option[:value]}]"
#  end
#
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
      each_tweet do |content, img_url, name, url|
        response = post_entry(content, img_url, name, url)
        if response.code == '201'
          JSON::parse(response.body)['entry']
        end
      end.compact! || []
    end
  end

  def post_entry content, img_url, name, url
    access_token.post "#{target_group_url}/entries.json", {
      'entry[content]' => content,
      'entry[attachment_attributes][data][user][img_url]' => img_url,
      'entry[attachment_attributes][data][user][name]' => name,
      'entry[attachment_attributes][data][url]' => url,
      'entry[attachment_attributes][attachment_type]' => 'twitter'
    }
  end

  def access_token
    @access_token ||= OAuth::AccessToken.new(consumer, configatron.access_token.key, configatron.access_token.secret)
  end

  def consumer
   @consumer ||= OAuth::Consumer.new(configatron.consumer.key, configatron.consumer.secret, :site => "http://#{configatron.url_options[:host]}:#{configatron.url_options[:port]}")
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
      yield(content, img_url, name, url)
    end
  end

  def get
    logger.info " >> url: #{url}"
    logger.info " >> query: #{query.inspect}"
    @response = HTTParty.get(url, :query => self.query, :format => :json, :headers => {'User-Agent' => USER_AGENT})
  end

  def items
    @items ||= if @response.is_a?(Hash)
                 @response["results"]
               else
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
#
#  def participation
#    @participation ||= self.group.participation(self.class.fetch_user)
#  end
#
#  def fetch_user_picture
#    fetch_user.participations.first.picture
#  end
#
end
