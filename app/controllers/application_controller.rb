class ApplicationController < ActionController::Base  
  # Detect mobile browser and switch to mobile format, defined as MIME type. 
  before_filter :prepare_for_mobile
  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ef6844519c2aaf111cabba8ce89d66eb'

  # Redirect to profile page when user first creates account
  def after_sign_in_path_for(resource)
    user_path(resource.username)
  end
  
  private

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    elsif request.env["SERVER_NAME"] =~ /^mobile/
      true
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end
  
end