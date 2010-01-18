pit = if ['test', 'cucumber'].include?(::Rails.env)
        { 'host' => "example.com" }
      else
        Pit.get('hostname', :require => { 'host' => '', 'port' => ''})
      end

ActionController::Base.session_options[:domain] = ".#{pit['host']}"

url_options= { :host => pit['host'] }
url_options.merge!(:port => pit['port']) unless pit['port'].blank? or pit['port'] == "80"

configatron.url_options = ActionMailer::Base.default_url_options = url_options
