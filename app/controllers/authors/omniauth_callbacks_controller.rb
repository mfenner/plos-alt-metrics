class Authors::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  
  def twitter
    @author = Author.find_for_twitter_oauth(env['omniauth.auth'])

    if @author.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', :kind => 'Twitter'
      @author.remember_me = true
      sign_in_and_redirect @author, :event => :authentication
    else
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.failure', :kind => 'Twitter'
      redirect_to root_path
    end
  end

  def mendeley
    raise request.env["omniauth.auth"].to_yaml
  end
  
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
  
  protected

  # This is necessary since Rails 3.0.4
  # See https://github.com/intridea/omniauth/issues/185
  # and http://www.arailsdemo.com/posts/44
  def handle_unverified_request
    true
  end
  
end