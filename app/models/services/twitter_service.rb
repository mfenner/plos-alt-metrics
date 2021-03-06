require 'omniauth-twitter'
require "twitter"

class TwitterService < Service

  def self.update_via_twitter(user)
  
    begin
      # Update user info. Leave image empty if Twitter provides only default profile image
      twitter_user = Twitter.user(user.username)
      image = Twitter.profile_image(user.username, :size => 'original')
      image = nil if image.match(/default_profile_images/)
      user.update_attributes(:twitter => twitter_user.id, :location => twitter_user.location, :description => twitter_user.description, :website => twitter_user.url, :image => image)

      # Find Twitter friends
      friends_ids = Twitter.friend_ids(user.username).ids
      unless friends_ids.blank?
        user.friendships.clear
        friends_ids.each do |friend_id|
          friend = User.find_by_twitter(friend_id)
          if friend and !user.friends.include?(friend)
            user.friends << friend 
          end
        end
      end
    rescue Twitter::Unauthorized
      Rails.logger.debug "Twitter query error: not authorized to get friends from #{user.username}"
    rescue Twitter::BadRequest
      Rails.logger.debug "Twitter rate limit exceeded"
    end
    
    user
  end
  
end
