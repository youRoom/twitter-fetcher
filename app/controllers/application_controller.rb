# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  layout 'application'

  before_filter :require_group
  before_filter :require_login

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def render_not_found
    logger.info "headers: #{request.headers.map{ |k,v| "{#{k}:#{v}}"}.join(' ')}"
    respond_to do |format|
      format.html { render "public/404.html", :layout => false, :status => :not_found }
      format.all { head :not_found }
    end
  end

  private
  def require_group
    unless params[:group_id]
      render_not_found
      return
    end
  end

  def require_login
    if session[:access_token].blank?
      redirect_to verify_group_oauth_url(params[:group_id])
      return
    else
      return true if authorize?
      render_not_found
    end
  end

  def authorize?
    res = access_token.get "http://r#{params[:group_id]}.#{configatron.url_options[:host]}:#{configatron.url_options[:port]}/participations/current_participation.json"
    case res
    when Net::HTTPSuccess
      participation = JSON.parse(res.body)['participation']
      if participation &&  participation['admin']
        session[:access_token] = access_token.token
        session[:access_token_secret] = access_token.secret
        return true
      else
        reset_session
      end
    end
  rescue OAuth::Unauthorized => e
    reset_session
  end

  def consumer
    @consumer ||= OAuth::Consumer.new(configatron.consumer.key, configatron.consumer.secret, :site => "http://#{configatron.url_options[:host]}:#{configatron.url_options[:port]}")
  end

  def access_token
    @access_token ||=
      if session[:access_token]
        OAuth::AccessToken.new(consumer, session[:access_token], session[:access_token_secret])
      else
        request_token = OAuth::RequestToken.new(consumer, session[:request_token], session[:request_token_secret])
        request_token.get_access_token({}, :oauth_token => params[:oauth_token], :oauth_verifier => params[:oauth_verifier])
      end
  end
end
