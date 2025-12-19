require_relative "lib/railspress/version"

Gem::Specification.new do |spec|
  spec.name        = "railspress"
  spec.version     = Railspress::VERSION
  spec.authors     = ["Avi Flombaum"]
  spec.email       = ["avi@example.com"]
  spec.homepage    = "https://github.com/aviflombaum/railspress"
  spec.summary     = "A simple blog engine for Rails"
  spec.description = "RailsPress provides blog functionality with categories, tags, and rich text editing."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aviflombaum/railspress"
  spec.metadata["changelog_uri"] = "https://github.com/aviflombaum/railspress/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "lexxy", "~> 0.1.23.beta"
end
