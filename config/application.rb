require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Rpiflix
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
	
	config.before_initialize do
		# not sure where else to put this, but here seems to work
	
		require 'activerecord-import/base'
		module ActiveRecord::Import
			class << self
				def base_adapter_with_jdbc_patch(adapter)
					# drop jdbc from name, so ar-import picks the appropriate adapter
					base_adapter_without_jdbc_patch adapter.sub('jdbc', '')
				end
				
				alias_method_chain :base_adapter, :jdbc_patch
			end
		end
    end
	
	config.autoload_paths += Dir["#{config.root}/lib"]
	
	# max number of threads to use for training / scoring
	config.max_threads = 2
  end
end
