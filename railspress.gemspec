require_relative "lib/railspress/version"

Gem::Specification.new do |spec|
  spec.name        = "railspress-engine"
  spec.version     = Railspress::VERSION
  spec.authors     = [ "Avi Flombaum" ]
  spec.email       = [ "git@avi.nyc" ]
  spec.homepage    = "https://railspress.org"
  spec.summary     = "A mountable blog + CMS engine for Rails 8+"
  spec.description = "RailsPress gives your Rails app a complete content management system: a blog with categories and tags, structured entities with custom schemas, and editable site blocks with inline editing — all behind a namespaced admin interface."
  spec.license     = "Nonstandard"

  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aviflombaum/railspress-engine"
  spec.metadata["changelog_uri"] = "https://github.com/aviflombaum/railspress-engine/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,docs,lib}/**/*", "CHANGELOG.md", "LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3.1"
  spec.add_dependency "lexxy", ">= 0.9.29"
  spec.add_dependency "stimulus-rails", ">= 1.2.2"
  spec.add_dependency "image_processing", "~> 2.0", ">= 2.0.3"
  spec.add_dependency "rubyzip", ">= 2.3"
  spec.add_dependency "redcarpet", ">= 3.6"
  spec.add_dependency "ssrf_filter", "~> 1.5"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "debug"

  spec.post_install_message = <<~MSG

    ============================================================
      RailsPress installed/updated.

      New install:
        $ bin/rails generate railspress:install
        $ bin/rails db:migrate
        $ bin/rails railspress:doctor

      Upgrading existing app:
        $ DRY_RUN=1 bin/rails railspress:upgrade
        $ bin/rails railspress:upgrade

      The mutating upgrade task is for writable development checkouts and
      runs all pending host migrations. Commit copied migrations and use the
      host application's normal db:migrate release step in production.

      Enabling Agents & API requires host-managed Active Record Encryption
      credentials. If they are missing, generate the credentials snippet with:
        $ bin/rails db:encryption:init

      RailsPress never generates or writes these credentials.

      Guides:
        - Install/setup: packaged README.md + docs/CONFIGURING.md
        - Upgrading: packaged docs/UPGRADING.md
        - Full docs: https://railspress.org
    ============================================================

  MSG
end
