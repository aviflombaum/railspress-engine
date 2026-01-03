# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Railspress
  module Generators
    class EntityGenerator < Rails::Generators::NamedBase
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      desc "Generate a RailsPress-managed entity with model, migration, and registration"

      def create_model_file
        template "model.rb.tt", File.join("app/models", "#{file_name}.rb")
      end

      def create_migration
        migration_template "migration.rb.tt", File.join(db_migrate_path, "create_#{table_name}.rb")
      end

      def add_registration
        initializer_file = "config/initializers/railspress.rb"

        unless File.exist?(initializer_file)
          create_file initializer_file, <<~RUBY
            # frozen_string_literal: true

            Railspress.configure do |config|
              # Register your CMS-managed entities here
              # config.register_entity Project
            end
          RUBY
          say_status :created, "RailsPress initializer", :green
        end

        inject_into_file initializer_file, after: "Railspress.configure do |config|\n" do
          "  config.register_entity #{class_name}\n"
        end

        say_status :registered, "#{class_name} entity", :green
      end

      def show_next_steps
        say ""
        say "=" * 60, :green
        say "  Entity #{class_name} created!", :green
        say "=" * 60, :green
        say ""
        say "Next steps:", :yellow
        say ""
        say "  1. Run the migration:"
        say "     $ rails db:migrate", :cyan
        say ""
        say "  2. Restart your Rails server"
        say ""
        say "  3. Access #{class_name} in the admin:"
        say "     /railspress/admin/entities/#{table_name}", :cyan
        say ""
        say "=" * 60, :green
      end

      private

      def db_migrate_path
        "db/migrate"
      end

      def rich_text_fields
        attributes.select { |a| a.type == :rich_text }
      end

      def regular_attributes
        attributes.reject { |a| a.type == :rich_text }
      end

      def railspress_field_names
        attributes.map { |a| ":#{a.name}" }.join(", ")
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
