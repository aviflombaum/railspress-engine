# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"

module Railspress
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install RailsPress: copy migrations, mount engine, and configure JavaScript"

      def copy_railspress_migrations
        rake "railspress:install:migrations"
      end

      def copy_action_text_migrations
        if action_text_migration_exists?
          say_status :skip, "ActionText migrations already exist", :yellow
        else
          say_status :create, "ActionText migrations", :green
          rake "railties:install:migrations FROM=action_text"
        end
      end

      def copy_active_storage_migrations
        if active_storage_migration_exists?
          say_status :skip, "ActiveStorage migrations already exist", :yellow
        else
          say_status :create, "ActiveStorage migrations", :green
          rake "railties:install:migrations FROM=active_storage"
        end
      end

      def mount_engine
        route_content = 'mount Railspress::Engine => "/railspress"'

        if File.read(rails_route_file).include?("Railspress::Engine")
          say_status :skip, "RailsPress engine already mounted", :yellow
        else
          route route_content
          say_status :mounted, "RailsPress engine at /railspress", :green
        end
      end

      def configure_importmap
        return unless importmap_available?

        importmap_file = Rails.root.join("config", "importmap.rb")
        importmap_content = File.read(importmap_file)

        # Pin ActiveStorage (required for ActionText attachments)
        unless importmap_content.include?("@rails/activestorage")
          append_to_file importmap_file, <<~RUBY

            # ActiveStorage for file uploads
            pin "@rails/activestorage", to: "activestorage.esm.js"
          RUBY
          say_status :pinned, "@rails/activestorage in importmap", :green
        end

        # Pin Lexxy editor
        if importmap_content.include?('"lexxy"')
          say_status :skip, "Lexxy already pinned in importmap", :yellow
        else
          append_to_file importmap_file, <<~RUBY

            # RailsPress rich text editor
            pin "lexxy", to: "lexxy.js"
          RUBY
          say_status :pinned, "Lexxy in importmap", :green
        end
      end

      def configure_javascript
        return unless importmap_available?

        application_js = Rails.root.join("app", "javascript", "application.js")
        return unless File.exist?(application_js)

        js_content = File.read(application_js)

        if js_content.include?('import "lexxy"')
          say_status :skip, "Lexxy already imported in application.js", :yellow
        else
          append_to_file application_js, <<~JS

            // RailsPress rich text editor
            import "lexxy"
          JS
          say_status :added, "Lexxy import to application.js", :green
        end
      end

      def show_post_install_message
        say ""
        say "=" * 60, :green
        say "  RailsPress installed successfully!", :green
        say "=" * 60, :green
        say ""
        say "Next steps:", :yellow
        say ""
        say "  1. Run migrations:"
        say "     $ rails db:migrate", :cyan
        say ""
        say "  2. Access the admin dashboard:"
        say "     http://localhost:3000/railspress/admin", :cyan
        say ""
        say "  3. (Optional) Change the mount path in config/routes.rb:"
        say "     mount Railspress::Engine => \"/blog\"", :cyan
        say ""
        say "JavaScript setup:", :yellow
        say "  The installer added Lexxy (rich text editor) to your importmap"
        say "  and application.js. If you use a custom JS entry point, add:"
        say ""
        say "     import \"lexxy\"", :cyan
        say ""
        say "=" * 60, :green
      end

      private

      def rails_route_file
        Rails.root.join("config", "routes.rb")
      end

      def migrations_dir
        Rails.root.join("db", "migrate")
      end

      def action_text_migration_exists?
        Dir.glob(migrations_dir.join("*_create_action_text_tables*.rb")).any?
      end

      def active_storage_migration_exists?
        Dir.glob(migrations_dir.join("*_create_active_storage_tables*.rb")).any?
      end

      def importmap_available?
        defined?(Importmap) && Rails.root.join("config", "importmap.rb").exist?
      end
    end
  end
end
