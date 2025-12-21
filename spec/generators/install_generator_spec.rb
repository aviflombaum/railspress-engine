# frozen_string_literal: true

require "rails_helper"
require "generators/railspress/install/install_generator"

RSpec.describe Railspress::Generators::InstallGenerator, type: :generator do
  let(:generator) { described_class.new }

  describe "#copy_railspress_migrations" do
    it "runs railspress:install:migrations rake task" do
      allow(generator).to receive(:rake)

      generator.copy_railspress_migrations

      expect(generator).to have_received(:rake).with("railspress:install:migrations")
    end
  end

  describe "#copy_action_text_migrations" do
    context "when ActionText migrations already exist" do
      it "skips and does not run rake" do
        allow(generator).to receive(:action_text_migration_exists?).and_return(true)
        allow(generator).to receive(:say_status)
        allow(generator).to receive(:rake)

        generator.copy_action_text_migrations

        expect(generator).to have_received(:say_status).with(:skip, "ActionText migrations already exist", :yellow)
        expect(generator).not_to have_received(:rake)
      end
    end

    context "when ActionText migrations do not exist" do
      it "runs rake with correct single-string command" do
        allow(generator).to receive(:action_text_migration_exists?).and_return(false)
        allow(generator).to receive(:say_status)
        allow(generator).to receive(:rake)

        generator.copy_action_text_migrations

        # Critical: must be single string, not two arguments
        expect(generator).to have_received(:rake).with("railties:install:migrations FROM=action_text")
      end
    end
  end

  describe "#copy_active_storage_migrations" do
    context "when ActiveStorage migrations already exist" do
      it "skips and does not run rake" do
        allow(generator).to receive(:active_storage_migration_exists?).and_return(true)
        allow(generator).to receive(:say_status)
        allow(generator).to receive(:rake)

        generator.copy_active_storage_migrations

        expect(generator).to have_received(:say_status).with(:skip, "ActiveStorage migrations already exist", :yellow)
        expect(generator).not_to have_received(:rake)
      end
    end

    context "when ActiveStorage migrations do not exist" do
      it "runs rake with correct single-string command" do
        allow(generator).to receive(:active_storage_migration_exists?).and_return(false)
        allow(generator).to receive(:say_status)
        allow(generator).to receive(:rake)

        generator.copy_active_storage_migrations

        # Critical: must be single string, not two arguments
        expect(generator).to have_received(:rake).with("railties:install:migrations FROM=active_storage")
      end
    end
  end

  describe "#mount_engine" do
    let(:routes_file) { Rails.root.join("config", "routes.rb") }

    context "when engine is not already mounted" do
      it "adds the engine mount via route helper" do
        allow(File).to receive(:read).with(routes_file).and_return("Rails.application.routes.draw do\nend")
        allow(generator).to receive(:say_status)
        allow(generator).to receive(:route)

        generator.mount_engine

        expect(generator).to have_received(:route).with('mount Railspress::Engine => "/railspress"')
        expect(generator).to have_received(:say_status).with(:mounted, "RailsPress engine at /railspress", :green)
      end
    end

    context "when engine is already mounted" do
      it "skips mounting" do
        allow(File).to receive(:read).with(routes_file).and_return('mount Railspress::Engine => "/blog"')
        allow(generator).to receive(:say_status)
        allow(generator).to receive(:route)

        generator.mount_engine

        expect(generator).to have_received(:say_status).with(:skip, "RailsPress engine already mounted", :yellow)
        expect(generator).not_to have_received(:route)
      end
    end
  end

  describe "#show_post_install_message" do
    it "displays success message and next steps" do
      messages = []
      allow(generator).to receive(:say) { |msg, *| messages << msg.to_s }

      generator.show_post_install_message

      output = messages.join("\n")
      expect(output).to include("RailsPress installed successfully")
      expect(output).to include("rails db:migrate")
      expect(output).to include("/railspress/admin")
    end
  end

  describe "migration detection" do
    let(:migrations_dir) { Rails.root.join("db", "migrate") }

    describe "#action_text_migration_exists?" do
      it "detects existing ActionText migration" do
        # Uses real Dir.glob against dummy app which has the migration
        expect(generator.send(:action_text_migration_exists?)).to be true
      end
    end

    describe "#active_storage_migration_exists?" do
      it "detects existing ActiveStorage migration" do
        # Uses real Dir.glob against dummy app which has the migration
        expect(generator.send(:active_storage_migration_exists?)).to be true
      end
    end
  end

  describe "integration: does not invoke action_text:install generator" do
    it "never calls generate with action_text:install" do
      # Stub external calls but verify we never try to run the problematic generator
      allow(generator).to receive(:rake)
      allow(generator).to receive(:say_status)
      allow(generator).to receive(:action_text_migration_exists?).and_return(false)

      generator.copy_action_text_migrations

      expect(generator).not_to have_received(:rake).with(/action_text:install/)
    end
  end

  describe "#configure_importmap" do
    let(:importmap_file) { Rails.root.join("config", "importmap.rb") }

    context "when importmap is not available" do
      it "does nothing" do
        allow(generator).to receive(:importmap_available?).and_return(false)
        allow(generator).to receive(:append_to_file)

        generator.configure_importmap

        expect(generator).not_to have_received(:append_to_file)
      end
    end

    context "when lexxy is not pinned" do
      it "adds lexxy pin to importmap" do
        allow(generator).to receive(:importmap_available?).and_return(true)
        allow(File).to receive(:read).with(importmap_file).and_return('pin "application"')
        allow(generator).to receive(:append_to_file)
        allow(generator).to receive(:say_status)

        generator.configure_importmap

        expect(generator).to have_received(:append_to_file).with(importmap_file, /pin "lexxy"/)
        expect(generator).to have_received(:say_status).with(:pinned, "Lexxy in importmap", :green)
      end
    end

    context "when lexxy is already pinned" do
      it "skips pinning" do
        allow(generator).to receive(:importmap_available?).and_return(true)
        allow(File).to receive(:read).with(importmap_file).and_return('pin "lexxy", to: "lexxy.js"')
        allow(generator).to receive(:append_to_file)
        allow(generator).to receive(:say_status)

        generator.configure_importmap

        expect(generator).to have_received(:say_status).with(:skip, "Lexxy already pinned in importmap", :yellow)
      end
    end
  end

  describe "#configure_javascript" do
    let(:application_js) { Rails.root.join("app", "javascript", "application.js") }

    context "when importmap is not available" do
      it "does nothing" do
        allow(generator).to receive(:importmap_available?).and_return(false)
        allow(generator).to receive(:append_to_file)

        generator.configure_javascript

        expect(generator).not_to have_received(:append_to_file)
      end
    end

    context "when application.js does not exist" do
      it "does nothing" do
        allow(generator).to receive(:importmap_available?).and_return(true)
        allow(File).to receive(:exist?).with(application_js).and_return(false)
        allow(generator).to receive(:append_to_file)

        generator.configure_javascript

        expect(generator).not_to have_received(:append_to_file)
      end
    end

    context "when lexxy is not imported" do
      it "adds lexxy import to application.js" do
        allow(generator).to receive(:importmap_available?).and_return(true)
        allow(File).to receive(:exist?).with(application_js).and_return(true)
        allow(File).to receive(:read).with(application_js).and_return('import "@hotwired/turbo-rails"')
        allow(generator).to receive(:append_to_file)
        allow(generator).to receive(:say_status)

        generator.configure_javascript

        expect(generator).to have_received(:append_to_file).with(application_js, /import "lexxy"/)
        expect(generator).to have_received(:say_status).with(:added, "Lexxy import to application.js", :green)
      end
    end

    context "when lexxy is already imported" do
      it "skips importing" do
        allow(generator).to receive(:importmap_available?).and_return(true)
        allow(File).to receive(:exist?).with(application_js).and_return(true)
        allow(File).to receive(:read).with(application_js).and_return('import "lexxy"')
        allow(generator).to receive(:append_to_file)
        allow(generator).to receive(:say_status)

        generator.configure_javascript

        expect(generator).to have_received(:say_status).with(:skip, "Lexxy already imported in application.js", :yellow)
        expect(generator).not_to have_received(:append_to_file)
      end
    end
  end
end
