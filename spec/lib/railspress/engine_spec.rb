# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe Railspress::Engine do
  describe "RailsPress deprecator" do
    it "uses the RailsPress 2.0 removal horizon" do
      expect(Railspress.deprecator.gem_name).to eq("RailsPress")
      expect(Railspress.deprecator.deprecation_horizon).to eq("2.0")
    end

    it "registers with the host application" do
      expect(Rails.application.deprecators[:railspress]).to equal(Railspress.deprecator)
    end
  end

  describe "CMS helper load hook" do
    it "does not depend on app helper autoload timing" do
      script = <<~RUBY
        require "rails/all"
        require "railspress"

        Railspress.reset_configuration!

        initializer = Railspress::Engine.initializers.find { |item| item.name == "railspress.cms_helper" }
        initializer.bind(Railspress::Engine.instance).run(nil)

        ActiveSupport.run_load_hooks(:action_view, Class.new)
      RUBY

      stdout, stderr, status = Open3.capture3("bundle", "exec", "ruby", "-Ilib", "-e", script)
      expect(status).to be_success, "#{stdout}\n#{stderr}"
      expect(stderr).not_to include("require_dependency is deprecated")
    end
  end
end
