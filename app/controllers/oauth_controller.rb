class OauthController < ApplicationController
  skip_before_filter :require_login, :only => %w(verify_youroom callback_youroom)

  def verify_youroom
    request_token = youroom_consumer.get_request_token(:oauth_callback => callback_youroom_group_oauth_url(params[:group_id]))
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def callback_youroom
    if authorize?
      redirect_to group_twitter_fetchers_url(params[:group_id])
    else
      render_not_found
    end
  end

  def verify_twitter
    request_token = twitter_consumer.get_request_token(:oauth_callback => callback_twitter_group_oauth_url(params[:group_id]))
    session[:twitter_request_token] = request_token.token
    session[:twitter_request_token_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def callback_twitter
    request_token = OAuth::RequestToken.new(twitter_consumer, session[:twitter_request_token], session[:twitter_request_token_secret])
    access_token = request_token.get_access_token({}, :oauth_token => params[:oauth_token], :oauth_verifier => params[:oauth_verifier])
    session[:twitter_access_token] = access_token.token
    session[:twitter_access_token_secret] = access_token.secret
    redirect_to new_group_twitter_fetcher_url(params[:group_id])
  end

  private
  def twitter_consumer
    @twitter_consumer ||= OAuth::Consumer.new(configatron.twitter.consumer.key, configatron.twitter.consumer.secret, :site => "http://twitter.com")
  end
end

