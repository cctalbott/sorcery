module Sorcery
  module Controller
    module Submodules
      module External
        module Providers
          # This module adds support for OAuth with facebook.com.
          # When included in the 'config.providers' option, it adds a new option, 'config.facebook'.
          # Via this new option you can configure Facebook specific settings like your app's key and secret.
          #
          #   config.facebook.key = <key>
          #   config.facebook.secret = <secret>
          #   ...
          #
          module Facebook
            def self.included(base)
              base.module_eval do
                class << self
                  attr_reader :facebook                           # access to facebook_client.
                  
                  def merge_facebook_defaults!
                    @defaults.merge!(:@facebook => FacebookClient)
                  end
                end
                merge_facebook_defaults!
                update!
              end
            end
          
            module FacebookClient
              class << self
                attr_accessor :key,
                              :secret,
                              :callback_url,
                              :site,
                              :user_info_path,
                              :scope,
                              :user_info_mapping,
                              :display
                attr_reader   :access_token

                include Protocols::Oauth2
            
                def init
                  @site           = "https://graph.facebook.com"
                  @user_info_path = "/me"
                  @scope          = "email,offline_access"
                  @user_info_mapping = {}
                  @display        = "page"
                end
                
                def get_user_hash
                  user_hash = {}
                  response = @access_token.get(@user_info_path)
                  user_hash[:user_info] = JSON.parse(response.body)
                  user_hash[:uid] = user_hash[:user_info]['id']
                  user_hash
                end
                
                def has_callback?
                  true
                end
                
                # calculates and returns the url to which the user should be redirected,
                # to get authenticated at the external provider's site.
                def login_url(params,session)
                  self.authorize_url
                end
                
                # tries to login the user from access token
                def process_callback(params,session)
                  args = {}
                  args.merge!({:code => params[:code]}) if params[:code]
                  options = {:token_url => 'oauth/access_token'}
                  @access_token = self.get_access_token(args, options)
                end

                # overrided fo protocols/oauth2.rb
                def get_access_token(args, options = {})
                  client = build_client(options)
                  client.auth_code.get_token(
                    args[:code],
                    {
                      :redirect_uri => @callback_url,
                      :parse => :query
                    },
                    {
                      :header_format => 'OAuth %s'
                    }
                  )
                end
                
              end
              init
            end
            
          end
        end    
      end
    end
  end
end
