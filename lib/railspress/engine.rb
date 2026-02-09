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

    # Make CMS helper available to host application views (or stub when disabled)
    initializer "railspress.cms_helper" do
      ActiveSupport.on_load(:action_view) do
        if Railspress.cms_enabled?
          include Railspress::CmsHelper
        else
          include Railspress::CmsHelper::DisabledStub
        end
      end
    end

    # Clear CMS cache on each request in development
    initializer "railspress.cms_cache" do |app|
      if Railspress.cms_enabled?
        app.config.to_prepare do
          Railspress::CmsHelper.clear_cache
        end
      end
    end

    # Validate configuration after all initializers have run
    initializer "railspress.validate_config" do
      if Railspress.inline_editing_check && !Railspress.cms_enabled?
        raise Railspress::ConfigurationError,
          "Inline editing requires CMS. Add `config.enable_cms` to your initializer."
      end
    end

    # Configure importmap for Stimulus controllers
    initializer "railspress.importmap", before: "importmap" do |app|
      if app.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config", "importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app", "javascript")
      end
    end

  end
end
