class Authors::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  
  def twitter
    @author = Author.find_for_twitter_oauth(env['omniauth.auth'])

    if @author.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', :kind => 'Twitter'
      @author.remember_me = true
      sign_in_and_redirect @author, :event => :authentication
    else
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.failure', :kind => 'Twitter', :reason => 'Author not found'
      redirect_to new_author_session_path
    end
  end
  
  def mendeley
    raise request.env["omniauth.auth"].to_yaml
  end
  
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
  
end