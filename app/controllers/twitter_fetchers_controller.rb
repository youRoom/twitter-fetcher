class TwitterFetchersController < ApplicationController
  def index
    @fetchers = TwitterFetcher.group_id_equals(params[:group_id])
  end

  def new
    @fetcher = TwitterFetcher.new(:group_id => params[:group_id])
  end

  def create
    @fetcher = TwitterFetcher.new(params[:twitter_fetcher].merge(:group_id => params[:group_id]))
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

end
