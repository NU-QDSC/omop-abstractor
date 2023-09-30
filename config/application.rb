require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OmopAbstractor
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Initialize CLAMP config values
    APP_CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
    config.x.clamp.clamp_dir = APP_CONFIG['clamp_dir']
    config.x.clamp.clamp_bin = APP_CONFIG['clamp_bin']
    config.x.clamp.clamp_pipeline = APP_CONFIG['clamp_pipeline']
    config.autoload_paths << Rails.root.join('lib')
  end
end
