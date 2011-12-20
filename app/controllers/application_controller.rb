class ApplicationController < ActionController::Base  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ef6844519c2aaf111cabba8ce89d66eb'

  # Redirect to homepage after signing in
  def after_sign_in_path_for(resource)
    posts_path
  end
  
end