class ApplicationController < ActionController::Base  
  # Detect mobile browser and switch to mobile format, defined as MIME type. 
  # Uses mobile_fu gem
  #has_mobile_fu
  before_filter :prepare_for_mobile
  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ef6844519c2aaf111cabba8ce89d66eb'

  # Redirect to homepage after signing in
  def after_sign_in_path_for(resource)
    posts_path
  end

  private

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
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