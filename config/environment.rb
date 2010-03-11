# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

DB_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/database.yml")
if File.exists?(RAILS_ROOT+'/config/solr.yml')
  config = YAML::load_file(RAILS_ROOT+'/config/solr.yml')
  url = config[RAILS_ENV]['url']
  # for backwards compatibility
  url ||= "http://#{config[RAILS_ENV]['host']}:#{config[RAILS_ENV]['port']}/#{config[RAILS_ENV]['servlet_path']}"
elsif ENV['WEBSOLR_URL']
  url = ENV['WEBSOLR_URL']
else
  url = 'http://localhost:8983/solr'
end
ENV['WEBSOLR_URL'] = url

Rails::Initializer.run do |config|
  
  require 'core_extensions'
  config.gem 'paperclip'
  config.gem 'sunlight', :version => '>= 0.9'  
  config.gem "RedCloth", :version => ">= 3.0.4" #, :source => "http://code.whytheluckystiff.net/"
  config.gem 'googlecharts', :version => '1.3.6', :lib => 'gchart'
  config.gem 'oauth', :version => '>= 0.3.1'
  config.gem 'twitter-auth', :version => '0.1.21', :lib => 'twitter_auth'
  config.gem 'hpricot', :version => '>= 0.6'
  config.gem 'liquid'
  config.gem 'dweinand-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com/'
  config.gem 'facebooker', :version => '1.0.53'
  config.gem 'hoptoad_notifier'
  config.gem "rmagick", :lib => "RMagick2" # needs apt-get install imagemagick librmagick-ruby libmagickwand-dev OR libmagick9-dev
  config.gem 'daemons'
  #config.gem 'curb', :version => '0.1.4'
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')] 
  config.i18n.default_locale = DB_CONFIG[RAILS_ENV]['default_lang']
  
  NB_CONFIG = { 'api_exclude_fields' => [:ip_address, :user_agent, :referrer, :google_token, :google_crawled_at, :activation_code, :salt, :email, :first_name, :last_name, :crypted_password, :is_tagger, :partner_id, :ip_address, :user_agent, :remember_token, :remember_token_expires_at, :referrer, :zip, :birth_date, :city, :state, :is_comments_subscribed, :is_finished_subscribed, :is_followers_subscribed, :is_mergeable, :is_messages_subscribed, :is_newsletter_subscribed, :is_point_changes_subscribed, :is_votes_subscribed, :is_subscribed, :contacts_count, :contacts_invited_count, :contacts_members_count, :contacts_not_invited_count, :code, :rss_code, :address] }

end

HoptoadNotifier.configure do |config|
  config.api_key = ENV['HOPTOAD_KEY'] if ENV['HOPTOAD_KEY']
  config.development_lookup = false
end

require 'diff'
require 'open-uri'
require 'validates_uri_existence_of'
require 'timeout'

TagList.delimiter = ","

AutoHtml.add_filter(:redcloth) do |text|
  begin
    RedCloth.new(text).to_html
  rescue
    text
  end
end

class String
 def parameterize_full
    str=self.to_s.gsub("Ð","D").gsub("Þ","Th").gsub("Æ","Ae").gsub("ð","d").gsub("þ","th").gsub("æ","ae")
    accents = {
      ['á','à','â','ä','ã'] => 'a',
      ['Ã','Ä','Â','À','Á'] => 'A',
      ['é','è','ê','ë'] => 'e',
      ['Ë','É','È','Ê'] => 'E',
      ['í','ì','î','ï'] => 'i',
      ['Í','Î','Ì','Ï'] => 'I',
      ['ó','ò','ô','ö','õ'] => 'o',
      ['Õ','Ö','Ô','Ò','Ó'] => 'O',
      ['ú','ù','û','ü'] => 'u',
      ['Ú','Û','Ù','Ü'] => 'U',
      ['Ý'] => 'Y',
      ['ý'] => 'y',
      ['ç'] => 'c', ['Ç'] => 'C',
      ['ñ'] => 'n', ['Ñ'] => 'N'
    }
    accents.each do |ac,rep|
      ac.each do |s|
        str = str.gsub(s, rep)
      end
    end
    str = str.gsub(/[^a-zA-Z0-9 ]/,"")
    str = str.gsub(/[ ]+/," ")
    str = str.gsub(/ /,"-")
    str = str.downcase
  end
end

# RAILS 2.3.2
# this is a temporary hack to get around the fact that rails puts memorystore in front of memcached
# won't freeze the objects any more

class ActiveSupport::Cache::MemoryStore
  def write(name, value, options = nil)
    super
    #@data[name] = value.freeze
    @data[name] = value
  end
end


# /Library/Ruby/Gems/1.8/gems/rails-2.3.2/lib/rails/gem_dependency.rb:99:Warning: Gem::Dependency#version_requirements is deprecated and will be removed on or after August 2010.  Use #requirement
# https://rails.lighthouseapp.com/projects/8994/tickets/4026
# http://www.mattvsworld.com/blog/2010/03/version_requirements-deprecated-warning-in-rails/
# if Gem::VERSION >= "1.3.6"
#   module Rails
#     class GemDependency
#       def requirement
#         r = super
#         (r == Gem::Requirement.default) ? nil : r
#       end
#     end
#   end
# end