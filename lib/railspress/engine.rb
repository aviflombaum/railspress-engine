module Railspress
  class Engine < ::Rails::Engine
    isolate_namespace Railspress

    # Register engine assets with the asset pipeline (Propshaft)
    initializer "railspress.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app", "assets", "stylesheets").to_s
        app.config.assets.paths << root.join("app", "assets", "stylesheets", "railspress").to_s
        app.config.assets.paths << root.join("app", "assets", "javascripts").to_s
        app.config.assets.paths << root.join("app", "assets", "images").to_s
        app.config.assets.paths << root.join("app", "javascript").to_s
      end
    end

    # Configure importmap for Stimulus controllers
    initializer "railspress.importmap", before: "importmap" do |app|
      if app.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config", "importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app", "javascript")
      end
    end

    # Include Turbo helpers in admin views (deferred until app is ready)
    config.to_prepare do
      if defined?(::Turbo::FramesHelper)
        Railspress::Admin::BaseController.helper ::Turbo::FramesHelper
        Railspress::Admin::BaseController.helper ::Turbo::StreamsHelper
      end
    end
  end
end
