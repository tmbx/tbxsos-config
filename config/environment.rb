# Be sure to restart your web server when you modify this file.

#require RAILS_ROOT + '/lib/htmlhelpers'

TBXSOS_VERSION="1.3"
BACKUP_MIN_VERSION="0.1"
BACKUP_MAX_VERSION="1.3"

# borrowed from boot.rb - workaround for code bwlow
unless defined?(RAILS_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')

  unless RUBY_PLATFORM =~ /mswin32/
    require 'pathname'
    root_path = Pathname.new(root_path).cleanpath(true).to_s
  end

  RAILS_ROOT = root_path
end

# we need syslog and gettext before it's initialized normally
# they are made globally available everywhere
require RAILS_ROOT + '/lib/klogger.rb'
require RAILS_ROOT + '/lib/gettext_wrap.rb'

# (custom) syslog logger
KLOGGER = Klogger.new

# (custom) gettext wrapper
gettext_change_language()

# below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Include your application configuration below
def in_dev?
  return (! ENV.nil? && ! ENV['RAILS_ENV'].nil? && ENV['RAILS_ENV'] == "development")
end


# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  #config.load_paths += %W( #{RAILS_ROOT}/lib )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options

  config.action_controller.session = {
        :session_key => "_tbxsos-config",
        :secret => "4429f6fe-aba6-46b4-b8a1-40e8168c8d9f"
  }
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end


