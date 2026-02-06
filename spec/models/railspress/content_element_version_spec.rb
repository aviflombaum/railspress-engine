# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::ContentElementVersion, type: :model do
  fixtures "railspress/content_groups", "railspress/content_elements", "railspress/content_element_versions"

  let(:homepage_h1) { railspress_content_elements(:homepage_h1) }
  let(:version_1) { railspress_content_element_versions(:homepage_h1_v1) }

  describe "validations" do
    it "requires a content_element" do
      version = Railspress::ContentElementVersion.new(version_number: 1, text_content: "Test")
      expect(version).not_to be_valid
    end

    it "requires a version_number" do
      version = Railspress::ContentElementVersion.new(content_element: homepage_h1, text_content: "Test")
      expect(version).not_to be_valid
      expect(version.errors[:version_number]).to include("can't be blank")
    end

    it "requires unique version_number per content_element" do
      duplicate = Railspress::ContentElementVersion.new(
        content_element: homepage_h1,
        version_number: version_1.version_number,
        text_content: "Duplicate"
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:version_number]).to include("has already been taken")
    end

    it "allows same version_number for different elements" do
      tagline = railspress_content_elements(:tagline)
      # Version 1 already exists for tagline via fixture, so use version 99
      version = Railspress::ContentElementVersion.new(
        content_element: tagline,
        version_number: 99,
        text_content: "Test"
      )
      expect(version).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a content_element" do
      expect(version_1.content_element).to eq(homepage_h1)
    end
  end

  describe "scopes" do
    describe ".ordered" do
      it "orders by version_number desc" do
        # Create a second version
        homepage_h1.update!(text_content: "Changed content")
        versions = homepage_h1.content_element_versions.ordered
        version_numbers = versions.map(&:version_number)
        expect(version_numbers).to eq(version_numbers.sort.reverse)
      end
    end
  end

  describe "#changes_from_previous" do
    it "returns empty hash for first version" do
      expect(version_1.changes_from_previous).to eq({})
    end

    it "returns text_content changes from previous version" do
      # First update: creates version 2 storing the old content ("Welcome to Our Site")
      homepage_h1.update!(text_content: "Changed content")
      # Second update: creates version 3 storing "Changed content"
      homepage_h1.update!(text_content: "Changed again")
      # Version 3 ("Changed content") vs version 2 ("Welcome to Our Site") should show a diff
      latest_version = homepage_h1.content_element_versions.ordered.first
      changes = latest_version.changes_from_previous
      expect(changes).to have_key(:text_content)
      expect(changes[:text_content]).to be_an(Array)
      expect(changes[:text_content].length).to eq(2)
    end
  end
end
