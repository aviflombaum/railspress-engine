require_relative "lib/railspress/version"

Gem::Specification.new do |spec|
  spec.name        = "railspress-engine"
  spec.version     = Railspress::VERSION
  spec.authors     = [ "Avi Flombaum" ]
  spec.email       = [ "avi@flatironschool.com" ]
  spec.homepage    = "https://github.com/aviflombaum/railspress-engine"
  spec.summary     = "A mountable blog engine for Rails 8+"
  spec.description = "RailsPress provides drop-in blog functionality with categories, tags, rich text editing, and an admin interface."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aviflombaum/railspress-engine"
  spec.metadata["changelog_uri"] = "https://github.com/aviflombaum/railspress-engine/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1"
  spec.add_dependency "lexxy", "~> 0.1.24.beta"
  spec.add_dependency "rubyzip", ">= 2.3", "< 4.0"
  spec.add_dependency "redcarpet", "~> 3.6"

  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "capybara"

  spec.post_install_message = <<~MSG

    ============================================================
      RailsPress installed! Run the generator to complete setup:

        $ rails generate railspress:install

      This will:
        - Copy database migrations
        - Mount the engine in your routes
        - Install ActionText (if needed)
    ============================================================

  MSG
end
