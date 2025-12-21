# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"

module Railspress
  module Generators
    class AuthorsGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Enable author support for RailsPress posts"

      def create_migration
        migration_template(
          "add_author_to_railspress_posts.rb.tt",
          "db/migrate/add_author_to_railspress_posts.rb",
          migration_version: migration_version
        )
      end

      def create_initializer
        if initializer_exists?
          say_status :skip, "config/initializers/railspress.rb already exists", :yellow
          say ""
          say "Add the following to your existing initializer:", :yellow
          say ""
          say "  config.enable_authors", :cyan
          say "  config.author_class_name = \"User\"", :cyan
          say "  # config.author_scope = :admins", :cyan
          say "  # config.author_display_method = :name", :cyan
          say ""
        else
          template "railspress.rb.tt", "config/initializers/railspress.rb"
        end
      end

      def show_post_install_message
        say ""
        say "=" * 60, :green
        say "  RailsPress Authors enabled!", :green
        say "=" * 60, :green
        say ""
        say "Next steps:", :yellow
        say ""
        say "  1. Run migrations:"
        say "     $ rails db:migrate", :cyan
        say ""
        say "  2. Configure authors in config/initializers/railspress.rb", :cyan
        say ""
        say "  3. (Optional) Add an author scope to your User model:"
        say "     scope :authors, -> { where(role: :admin) }", :cyan
        say ""
        say "=" * 60, :green
      end

      private

      def initializer_exists?
        File.exist?(Rails.root.join("config", "initializers", "railspress.rb"))
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

      # Required for migration_template to work
      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end
    end
  end
end
