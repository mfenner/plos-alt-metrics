class ServicesController < ApplicationController
  def index
  end
  
  def create
    # You need to implement the method below in your model
    #@user = Author.find_for_twitter_oauth(env["omniauth.auth"], current_user)
    #if @user.persisted?
    #  flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Twitter"
    #  sign_in_and_redirect @user, :event => :authentication
    #else
    #  session["devise.twitter_data"] = env["omniauth.auth"]
    #  redirect_to new_user_registration_url
    #end
    render :text => request.env["omniauth.auth"].to_yaml
  end
  
  def failure
    render :text => request.env["omniauth.auth"].to_yaml
  end
  
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
end