class OauthController < ApplicationController
  skip_before_filter :require_login, :only => %w(verify callback)

  def verify
    request_token = consumer.get_request_token(:oauth_callback => callback_group_oauth_url(params[:group_id]))
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def callback
    if authorize?
      redirect_to group_twitter_fetchers_url(params[:group_id])
    else
      render_not_found
    end
  end
end

