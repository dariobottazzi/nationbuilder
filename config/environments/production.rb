# Settings specified here will take precedence over those in config/environment.rb

DB_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/database.yml")
domain = DB_CONFIG['production']['DOMAIN']

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

config.cache_store = :mem_cache_store, 'localhost:11211', { :namespace => DB_CONFIG['production']['MEMCACHE_NAMESPACE']}

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false

config.action_mailer.smtp_settings = {
  :address => "smtp.1984.is",
  :port => "25",
  :domain => domain
}


config.action_controller.session = {:domain => '.' + domain}
