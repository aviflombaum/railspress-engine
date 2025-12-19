require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)
require "railspress"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # Settings in config/environments/* take precedence over those specified here.
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
