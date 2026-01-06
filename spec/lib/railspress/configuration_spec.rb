# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::Configuration do
  before do
    Railspress.reset_configuration!
  end

  after do
    Railspress.reset_configuration!
  end

  describe "defaults" do
    it "has authors disabled by default" do
      expect(Railspress.authors_enabled?).to be false
    end

    it "has header images disabled by default" do
      expect(Railspress.post_images_enabled?).to be false
    end

    it "defaults author_class_name to User" do
      expect(Railspress.configuration.author_class_name).to eq("User")
    end

    it "defaults current_author_method to :current_user" do
      expect(Railspress.current_author_method).to eq(:current_user)
    end

    it "defaults author_scope to nil" do
      expect(Railspress.configuration.author_scope).to be_nil
    end

    it "defaults author_display_method to :name" do
      expect(Railspress.author_display_method).to eq(:name)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      Railspress.configure do |config|
        expect(config).to be_a(Railspress::Configuration)
      end
    end

    it "allows enabling authors with enable_authors" do
      Railspress.configure do |config|
        config.enable_authors
      end

      expect(Railspress.authors_enabled?).to be true
    end

    it "allows enabling post images with enable_post_images" do
      Railspress.configure do |config|
        config.enable_post_images
      end

      expect(Railspress.post_images_enabled?).to be true
    end

    it "allows setting author_class_name" do
      Railspress.configure do |config|
        config.author_class_name = "Admin"
      end

      expect(Railspress.configuration.author_class_name).to eq("Admin")
    end

    it "allows setting current_author_method" do
      Railspress.configure do |config|
        config.current_author_method = :current_admin
      end

      expect(Railspress.current_author_method).to eq(:current_admin)
    end

    it "allows setting author_scope as a symbol" do
      Railspress.configure do |config|
        config.author_scope = :admins
      end

      expect(Railspress.configuration.author_scope).to eq(:admins)
    end

    it "allows setting author_scope as a proc" do
      scope_proc = ->(klass) { klass.where(active: true) }

      Railspress.configure do |config|
        config.author_scope = scope_proc
      end

      expect(Railspress.configuration.author_scope).to eq(scope_proc)
    end

    it "allows setting author_display_method" do
      Railspress.configure do |config|
        config.author_display_method = :email
      end

      expect(Railspress.author_display_method).to eq(:email)
    end

    it "allows setting post_image_variants" do
      Railspress.configure do |config|
        config.post_image_variants = {
          hero: { resize_to_fill: [1920, 1080] },
          card: { resize_to_fill: [800, 500] }
        }
      end

      expect(Railspress.post_image_variants[:hero]).to eq({ resize_to_fill: [1920, 1080] })
      expect(Railspress.post_image_variants[:card]).to eq({ resize_to_fill: [800, 500] })
    end

    it "defaults post_image_variants to empty hash" do
      expect(Railspress.post_image_variants).to eq({})
    end
  end

  describe ".available_authors" do
    let(:mock_class) do
      Class.new do
        def self.all
          [:all_users]
        end

        def self.admins
          [:admin_users]
        end
      end
    end

    before do
      stub_const("User", mock_class)
      Railspress.configure do |config|
        config.enable_authors
        config.author_class_name = "User"
      end
    end

    context "with no scope configured" do
      it "returns all records" do
        expect(Railspress.available_authors).to eq([:all_users])
      end
    end

    context "with symbol scope" do
      it "calls the scope method on the class" do
        Railspress.configure { |c| c.author_scope = :admins }
        expect(Railspress.available_authors).to eq([:admin_users])
      end
    end

    context "with proc scope" do
      it "calls the proc with the class" do
        Railspress.configure do |c|
          c.author_scope = ->(klass) { [:custom_scope] }
        end

        expect(Railspress.available_authors).to eq([:custom_scope])
      end
    end
  end

  describe ".reset_configuration!" do
    it "resets to defaults" do
      Railspress.configure do |config|
        config.enable_authors
        config.enable_post_images
        config.author_class_name = "Admin"
      end

      Railspress.reset_configuration!

      expect(Railspress.authors_enabled?).to be false
      expect(Railspress.post_images_enabled?).to be false
      expect(Railspress.configuration.author_class_name).to eq("User")
    end
  end
end
