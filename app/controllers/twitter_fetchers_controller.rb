class TwitterFetchersController < ApplicationController
  before_filter :require_verify_twitter, :only => %w(new create)

  def index
    @fetchers = TwitterFetcher.group_id_equals(params[:group_id])
  end

  def new
    @fetcher = TwitterFetcher.new(:group_id => params[:group_id])
  end

  def create
    @fetcher = TwitterFetcher.new(params[:twitter_fetcher].merge({
      :group_id => params[:group_id],
      :access_token => session[:twitter_access_token],
      :access_token_secret => session[:twitter_access_token_secret]
    }))
    if @fetcher.save
      clear_twitter_token
      redirect_to :action => :index
    else
      render "new"
    end
  end

  def destroy
    @fetcher = TwitterFetcher.group_id_equals(params[:group_id]).find(params[:id])
    @fetcher.destroy
    redirect_to :action => :index
  end

  private
  def require_verify_twitter
    unless session[:twitter_access_token]
      redirect_to verify_twitter_group_oauth_url(params[:group_id])
      return
    end
  end

  def clear_twitter_token
    session[:twitter_request_token] = nil
    session[:twitter_request_token_secret] = nil
    session[:twitter_access_token] = nil
    session[:twitter_access_token_secret] = nil
  end
end
