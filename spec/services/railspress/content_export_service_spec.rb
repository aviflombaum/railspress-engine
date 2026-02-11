# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe Railspress::ContentExportService do
  fixtures "railspress/content_groups", "railspress/content_elements"

  describe "#call" do
    it "returns a Result with zip_data, filename, and counts" do
      result = described_class.new.call
      expect(result.zip_data).to be_present
      expect(result.filename).to match(/\Acms_content_\d{8}_\d{6}\.zip\z/)
      expect(result.group_count).to eq(2) # headers + footers (not deleted_group)
      expect(result.element_count).to eq(4) # homepage_h1 + tagline + required_element + footer_text (not deleted_element)
    end

    it "produces a valid ZIP containing content.json" do
      result = described_class.new.call
      entries = []
      Zip::InputStream.open(StringIO.new(result.zip_data)) do |zip|
        while (entry = zip.get_next_entry)
          entries << entry.name
        end
      end
      expect(entries).to include("content.json")
    end

    it "exports valid JSON manifest with version 1" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      expect(manifest["version"]).to eq(1)
      expect(manifest["exported_at"]).to be_present
      expect(manifest["source"]).to eq("RailsPress CMS")
      expect(manifest["groups"]).to be_an(Array)
    end

    it "exports active groups with their active elements" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      group_names = manifest["groups"].map { |g| g["name"] }
      expect(group_names).to include("Headers", "Footers")
      expect(group_names).not_to include("Deleted Group")

      headers_group = manifest["groups"].find { |g| g["name"] == "Headers" }
      element_names = headers_group["elements"].map { |e| e["name"] }
      expect(element_names).to include("Homepage H1", "Tagline")
      expect(element_names).not_to include("Deleted Element")
    end

    it "includes full metadata for elements" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      headers_group = manifest["groups"].find { |g| g["name"] == "Headers" }
      h1 = headers_group["elements"].find { |e| e["name"] == "Homepage H1" }

      expect(h1["content_type"]).to eq("text")
      expect(h1["position"]).to eq(1)
      expect(h1["text_content"]).to eq("Welcome to Our Site")
    end

    it "includes group descriptions" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      headers_group = manifest["groups"].find { |g| g["name"] == "Headers" }
      expect(headers_group["description"]).to eq("Site header content elements")
    end

    it "includes required flag for elements" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      headers_group = manifest["groups"].find { |g| g["name"] == "Headers" }
      required = headers_group["elements"].find { |e| e["name"] == "Site Title" }
      non_required = headers_group["elements"].find { |e| e["name"] == "Homepage H1" }

      expect(required["required"]).to be true
      expect(non_required["required"]).to be false
    end

    it "includes image_hint for elements" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      headers_group = manifest["groups"].find { |g| g["name"] == "Headers" }
      h1 = headers_group["elements"].find { |e| e["name"] == "Homepage H1" }
      expect(h1).to have_key("image_hint")
    end

    it "does not include author_id in export" do
      result = described_class.new.call
      manifest = extract_manifest(result.zip_data)

      manifest["groups"].each do |group|
        expect(group).not_to have_key("author_id")
        group["elements"].each do |el|
          expect(el).not_to have_key("author_id")
        end
      end
    end

    context "with empty database" do
      before do
        Railspress::ContentElementVersion.delete_all
        Railspress::ContentElement.delete_all
        Railspress::ContentGroup.delete_all
      end

      it "produces valid ZIP with empty groups array" do
        result = described_class.new.call
        manifest = extract_manifest(result.zip_data)

        expect(manifest["version"]).to eq(1)
        expect(manifest["groups"]).to eq([])
        expect(result.group_count).to eq(0)
        expect(result.element_count).to eq(0)
      end
    end
  end

  private

  def extract_manifest(zip_data)
    json = nil
    Zip::InputStream.open(StringIO.new(zip_data)) do |zip|
      while (entry = zip.get_next_entry)
        if entry.name == "content.json"
          json = entry.get_input_stream.read
          break
        end
      end
    end
    JSON.parse(json)
  end
end
