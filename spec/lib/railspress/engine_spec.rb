# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe Railspress::Engine do
  describe "controller isolation" do
    it "inherits browser controllers from the host application controller" do
      expect(Railspress::ApplicationController.superclass).to eq(::ApplicationController)
      expect(Railspress::Admin::BaseController < Railspress::ApplicationController).to be(true)
    end

    it "keeps API controllers outside the host application controller stack" do
      expect(Railspress::Api::V1::BaseController < ::ApplicationController).to be_nil
      expect(Railspress::Api::V1::BaseController < ActionController::API).to be(true)
    end

    it "keeps the old API actor controller helper with a 2.0 deprecation warning" do
      allow(Railspress.deprecator).to receive(:warn)
      controller = Railspress::Admin::BaseController.new
      allow(controller).to receive(:current_railspress_admin)

      controller.send(:current_api_actor)

      expect(Railspress.deprecator).to have_received(:warn).with(
        /current_api_actor.*removed in RailsPress 2\.0.*current_railspress_admin/
      )
    end
  end

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

  describe "importmap" do
    it "serves Stimulus locally instead of requiring a runtime CDN request" do
      importmap = File.read(Railspress::Engine.root.join("config/importmap.rb"))

      expect(importmap).to include('pin "@hotwired/stimulus", to: "stimulus.min.js"')
      expect(importmap).not_to include("ga.jspm.io")
    end
  end

  describe "admin assets" do
    it "does not require external font servers" do
      stylesheets = Dir[Railspress::Engine.root.join("app/assets/stylesheets/**/*.css")].map { |path| File.read(path) }

      expect(stylesheets.join).not_to include("fonts.googleapis.com", "fonts.gstatic.com")
    end
  end

  describe "configuration validation" do
    let(:initializer) do
      described_class.initializers.find { |item| item.name == "railspress.validate_config" }
    end

    after do
      Railspress.reset_configuration!
    end

    it "runs after host application initializers" do
      expect(initializer.after).to eq(:load_config_initializers)
    end

    it "raises the RailsPress encryption setup error during boot when the API is enabled" do
      encryption_options = ActiveSupport::OrderedOptions.new
      active_record_options = ActiveSupport::OrderedOptions.new
      application_config = ActiveSupport::OrderedOptions.new
      active_record_options.encryption = encryption_options
      application_config.active_record = active_record_options
      application = instance_double(Rails::Application, config: application_config, credentials: {})
      Railspress.configuration.enable_api

      expect {
        initializer.bind(described_class.instance).run(application)
      }.to raise_error(Railspress::ConfigurationError, /bin\/rails db:encryption:init/)
    end

    it "defers RailsPress boot errors while a diagnostic task loads the environment" do
      encryption_options = ActiveSupport::OrderedOptions.new
      active_record_options = ActiveSupport::OrderedOptions.new
      application_config = ActiveSupport::OrderedOptions.new
      active_record_options.encryption = encryption_options
      application_config.active_record = active_record_options
      application = instance_double(Rails::Application, config: application_config, credentials: {})
      Railspress.configuration.enable_api

      expect {
        Railspress.with_validation_reporting do
          initializer.bind(described_class.instance).run(application)
        end
      }.not_to raise_error
    end
  end
end
