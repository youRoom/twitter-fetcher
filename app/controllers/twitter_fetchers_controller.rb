class TwitterFetchersController < ApplicationController
  before_filter :require_verify_twitter, :only => %w(new create)
  before_filter :load_group

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

  def load_group
    @group = { :name => get_group_name, :picture => "#{Youroom.group_url(params[:group_id])}/picture" }

  end

  def get_group_name
    if group_name = Rails.cache.read(group_name_cache_key)
      group_name
    else
      res = access_token_as_youroom_user.get("#{Youroom.my_groups_url}.json")
      groups = JSON.parse(res.body)
      group = groups.detect{|group| group["group"]["id"].to_s == params[:group_id]}
      group_name = group["group"]["name"]
      Rails.cache.write(group_name_cache_key, group_name)
      group_name
    end
  end

  def group_name_cache_key(group_id = params[:group_id])
    "group_name/#{group_id}"
  end
end
