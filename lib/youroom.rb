class Youroom
  def self.root_url
    "http://#{configatron.youroom_url_options[:host]}:#{configatron.youroom_url_options[:port]}"
  end

  def self.group_url group_id
    "http://r#{group_id}.#{configatron.youroom_url_options[:host]}:#{configatron.youroom_url_options[:port]}"
  end
end
