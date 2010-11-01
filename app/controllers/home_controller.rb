class HomeController < ApplicationController
  skip_before_filter :require_group, :require_login
end
