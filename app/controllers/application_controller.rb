# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  layout 'application'

  before_filter :require_group, :require_login

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
      render "sessions/login_required"
      return
    else
      return true if authorize?
      render_not_found
    end
  end

  def authorize?
    # TODO 毎回youroom側にアクセスしないと認証出来ないのは微妙かも。利用者が少ないだろうし問題ないか?
    res = access_token_as_youroom_user.get "#{Youroom.group_url(params[:group_id])}/participations/current_participation.json"
    case res
    when Net::HTTPSuccess
      participation = JSON.parse(res.body)['participation']
      if participation &&  participation['application_admin']
        session[:access_token] = access_token_as_youroom_user.token
        session[:access_token_secret] = access_token_as_youroom_user.secret
        return true
      else
        reset_session
      end
    end
  rescue OAuth::Unauthorized => e
    reset_session
  end

  def youroom_consumer
    @youroom_consumer ||= OAuth::Consumer.new(configatron.youroom.consumer.key, configatron.youroom.consumer.secret, :site => Youroom.root_url)
  end

  def access_token_as_youroom_user
    @access_token_as_youroom_user ||=
      if session[:access_token]
        OAuth::AccessToken.new(youroom_consumer, session[:access_token], session[:access_token_secret])
      else
        request_token = OAuth::RequestToken.new(youroom_consumer, session[:request_token], session[:request_token_secret])
        request_token.get_access_token({}, :oauth_token => params[:oauth_token], :oauth_verifier => params[:oauth_verifier])
      end
  end
end
