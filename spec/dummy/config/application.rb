require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)
require "railspress"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # Settings in config/environments/* take precedence over those specified here.
    config.autoload_lib(ignore: %w[assets tasks])

    # Include engine migrations directly for testing.
    # Use absolute paths so db:migrate and maintain_test_schema! work
    # regardless of working directory (engine root vs dummy app root).
    config.paths["db/migrate"] << Railspress::Engine.root.join("db/migrate").to_s
  end
end
