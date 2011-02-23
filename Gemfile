source "http://rubygems.org"
source "http://gems.github.com"

gem 'rails', '2.3.9', :require => nil
gem 'mysql'

gem 'haml'
gem "searchlogic", ">=2.3.8"
gem 'configatron', :require => 'configatron'
gem 'pit', :require => "pit"
gem 'hoptoad_notifier'
gem 'twitter', "0.9.12"
gem "oauth"
gem "oauth-plugin"
gem "json"

# Devise 1.0.2 is not a valid gem plugin for Rails, so use git until 1.0.3
# gem 'devise', :git => 'git://github.com/plataformatec/devise.git', :ref => 'v1.0'

group :development do
  # bundler requires these gems in development
  gem "ruby-debug"
  gem "thin"
end

group :test do
  # bundler requires these gems while running tests
  gem 'rspec', '=1.3.1', :require => nil
  gem 'rspec-rails', '=1.3.3', :require => nil
  gem "spork",       :require => nil
end
