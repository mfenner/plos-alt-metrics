PlosAltMetrics::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  config.serve_static_assets = true
  
  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  #config.serve_static_assets = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!
  
  # Compress JavaScripts and CSS
  config.assets.compress = true
  
  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor  = :uglifier

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  config.action_mailer.default_url_options = { :host => 'sciencecard.org' }
  config.action_mailer.smtp_settings = { :enable_starttls_auto => false }
  
  # Configure Google Analytics, please add your settings
  config.middleware.use("Rack::GoogleAnalytics", :web_property_id => 'UA-362856-11')
  
  # Configure ExceptionNotifier
  config.middleware.use("ExceptionNotifier",
    :email_prefix => "[ScienceCard Error] ",
    :sender_address => %{"ScienceCard" <info@sciencecard.org>},
    :exception_recipients => %w{martin.h.fenner@googlemail.com})
end