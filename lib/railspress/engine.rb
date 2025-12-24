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
      end
    end
  end
end
