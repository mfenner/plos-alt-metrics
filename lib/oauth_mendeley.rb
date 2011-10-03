require 'omniauth/oauth'
require 'multi_json'

module OmniAuth
  module Strategies

    # Omniauth strategy for using 3-legged oauth and mendeley.com
    # Use OmniAuth::Strategies::Mendeley, 'consumerkey', 'consumersecret'
    class OauthMendeley < OmniAuth::Strategies::OAuth
      def initialize(app, consumer_key = nil, consumer_secret = nil, &block)
        client_options = {
          :site => 'http://www.mendeley.com',
          :request_token_path => "/oauth/request_token/",
          :access_token_path => "/oauth/access_token/",
          :authorize_path => "/oauth/authorize/",
          :http_method => :post,
          :scheme => :query_string
        }

        super(app, :oauth_mendeley, consumer_key, consumer_secret, client_options, &block)
      end
      
      def auth_hash
        OmniAuth::Utils.deep_merge(
          super, { 'uid' => user_data['uid'],
                   'user_info' => user_info })
      end

      def user_data
        @data ||= MultiJson.decode(@access_token.get('/0/account/info').body)
      end

      def user_info
        { 'name' => user_data['display_name'],
          'uid' => user_data['uid'],
          'email' => user_data['email'] }
      end
      
      def callback_phase
        session['oauth'][name.to_s]['callback_confirmed'] = true
        super
      end

    end
  end
end