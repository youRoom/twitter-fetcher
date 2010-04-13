class Youroom
  def self.root_url
    "http://#{configatron.youroom_url_options[:host]}:#{configatron.youroom_url_options[:port]}"
  end

  def self.group_url group_id
    scheme = if %w(production staging).include? ::Rails.env
               "https"
             else
               "http"
             end
    "#{scheme}://r#{group_id}.#{configatron.youroom_url_options[:host]}:#{configatron.youroom_url_options[:port]}"
  end
end
