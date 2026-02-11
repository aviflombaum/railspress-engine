# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe Railspress::ContentImportService do
  fixtures "railspress/content_groups", "railspress/content_elements"

  let(:headers_group) { railspress_content_groups(:headers) }
  let(:homepage_h1) { railspress_content_elements(:homepage_h1) }
  let(:deleted_element) { railspress_content_elements(:deleted_element) }
  let(:deleted_group) { railspress_content_groups(:deleted_group) }

  describe "#call" do
    context "creating new content" do
      it "creates new groups and elements" do
        manifest = build_manifest(groups: [
          { "name" => "New Group", "description" => "Brand new", "elements" => [
            { "name" => "New Element", "content_type" => "text", "position" => 1, "text_content" => "Hello" }
          ] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call

        expect(result.created).to eq(2) # 1 group + 1 element
        expect(result.errors).to be_empty
        expect(Railspress::ContentGroup.find_by(name: "New Group")).to be_present
        expect(Railspress::ContentElement.find_by(name: "New Element").text_content).to eq("Hello")
      end
    end

    context "updating existing content" do
      it "updates existing groups by name match" do
        manifest = build_manifest(groups: [
          { "name" => "Headers", "description" => "Updated description", "elements" => [] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call

        expect(result.updated).to eq(1)
        expect(headers_group.reload.description).to eq("Updated description")
      end

      it "updates existing elements by group+name match" do
        manifest = build_manifest(groups: [
          { "name" => "Headers", "description" => "Site header content elements", "elements" => [
            { "name" => "Homepage H1", "content_type" => "text", "position" => 1, "text_content" => "Updated Welcome" }
          ] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call

        expect(result.updated).to eq(2) # 1 group + 1 element
        expect(homepage_h1.reload.text_content).to eq("Updated Welcome")
      end

      it "fires auto-versioning on text_content changes" do
        manifest = build_manifest(groups: [
          { "name" => "Headers", "description" => "Site header content elements", "elements" => [
            { "name" => "Homepage H1", "content_type" => "text", "position" => 1, "text_content" => "Version Test" }
          ] }
        ])
        zip = build_zip(manifest)

        expect {
          described_class.new(zip).call
        }.to change { homepage_h1.content_element_versions.count }.by(1)
      end

      it "does not create version when text_content unchanged" do
        manifest = build_manifest(groups: [
          { "name" => "Headers", "description" => "Site header content elements", "elements" => [
            { "name" => "Homepage H1", "content_type" => "text", "position" => 1, "text_content" => "Welcome to Our Site" }
          ] }
        ])
        zip = build_zip(manifest)

        expect {
          described_class.new(zip).call
        }.not_to change { homepage_h1.content_element_versions.count }
      end
    end

    context "restoring soft-deleted records" do
      it "restores soft-deleted groups" do
        manifest = build_manifest(groups: [
          { "name" => "Deleted Group", "description" => "Restored!", "elements" => [] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call

        expect(result.restored).to eq(1)
        expect(deleted_group.reload.deleted?).to be false
        expect(deleted_group.description).to eq("Restored!")
      end

      it "restores soft-deleted elements" do
        manifest = build_manifest(groups: [
          { "name" => "Headers", "description" => "Site header content elements", "elements" => [
            { "name" => "Deleted Element", "content_type" => "text", "position" => 5, "text_content" => "Restored content" }
          ] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call

        expect(result.restored).to eq(1)
        expect(deleted_element.reload.deleted?).to be false
        expect(deleted_element.text_content).to eq("Restored content")
      end
    end

    context "required flag" do
      it "restores required flag on create" do
        manifest = build_manifest(groups: [
          { "name" => "New Group", "description" => "Test", "elements" => [
            { "name" => "Important", "content_type" => "text", "position" => 1, "text_content" => "Must exist", "required" => true }
          ] }
        ])
        zip = build_zip(manifest)

        described_class.new(zip).call

        element = Railspress::ContentElement.find_by(name: "Important")
        expect(element.required).to be true
      end

      it "defaults to false when required is absent" do
        manifest = build_manifest(groups: [
          { "name" => "New Group", "description" => "Test", "elements" => [
            { "name" => "Optional", "content_type" => "text", "position" => 1, "text_content" => "Not required" }
          ] }
        ])
        zip = build_zip(manifest)

        described_class.new(zip).call

        element = Railspress::ContentElement.find_by(name: "Optional")
        expect(element.required).to be false
      end
    end

    context "image_hint" do
      it "restores image_hint on create" do
        manifest = build_manifest(groups: [
          { "name" => "New Group", "description" => "Test", "elements" => [
            { "name" => "Banner", "content_type" => "image", "position" => 1, "image_hint" => "1920x600, 16:9" }
          ] }
        ])
        zip = build_zip(manifest)

        described_class.new(zip).call

        element = Railspress::ContentElement.find_by(name: "Banner")
        expect(element.image_hint).to eq("1920x600, 16:9")
      end
    end

    context "idempotency" do
      it "re-importing same ZIP produces no duplicates" do
        manifest = build_manifest(groups: [
          { "name" => "Headers", "description" => "Site header content elements", "elements" => [
            { "name" => "Homepage H1", "content_type" => "text", "position" => 1, "text_content" => "Welcome to Our Site" }
          ] }
        ])

        zip1 = build_zip(manifest)
        zip2 = build_zip(manifest)
        described_class.new(zip1).call

        expect {
          described_class.new(zip2).call
        }.not_to change(Railspress::ContentGroup, :count)
      end
    end

    context "error handling" do
      it "collects errors without stopping processing" do
        manifest = build_manifest(groups: [
          { "name" => "", "description" => "No name", "elements" => [] },
          { "name" => "Valid Group", "description" => "OK", "elements" => [] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call

        expect(result.errors).not_to be_empty
        expect(result.created).to be >= 1
      end

      it "rejects ZIP files without content.json" do
        zip = build_zip_without_manifest

        expect {
          described_class.new(zip).call
        }.to raise_error(ArgumentError, /content\.json/)
      end

      it "rejects invalid JSON" do
        zip = build_zip_with_content("not valid json {{{")

        expect {
          described_class.new(zip).call
        }.to raise_error(ArgumentError, /Invalid JSON/)
      end

      it "rejects invalid schema (missing version)" do
        zip = build_zip_with_content('{"groups": []}')

        expect {
          described_class.new(zip).call
        }.to raise_error(ArgumentError, /missing 'version'/)
      end

      it "rejects path traversal in ZIP entries" do
        manifest = build_manifest(groups: [
          { "name" => "Test", "description" => "Test", "elements" => [
            { "name" => "Evil", "content_type" => "image", "position" => 1, "image_path" => "../../../etc/passwd" }
          ] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call
        # Element created but image not attached (path rejected)
        expect(result.errors).to include(a_string_matching(/Image file missing/))
      end

      it "reports missing image files as errors" do
        manifest = build_manifest(groups: [
          { "name" => "Test Images", "description" => "test", "elements" => [
            { "name" => "Missing Img", "content_type" => "image", "position" => 1, "image_path" => "images/test/missing.png" }
          ] }
        ])
        zip = build_zip(manifest)

        result = described_class.new(zip).call
        expect(result.errors).to include(a_string_matching(/Image file missing/))
      end
    end

    context "clears CMS cache" do
      it "clears the CMS helper cache after import" do
        Railspress::CmsHelper.cache["test"] = "value"

        manifest = build_manifest(groups: [])
        zip = build_zip(manifest)
        described_class.new(zip).call

        expect(Railspress::CmsHelper.cache).to be_empty
      end
    end
  end

  private

  def build_manifest(groups:)
    {
      "version" => 1,
      "exported_at" => Time.current.iso8601,
      "source" => "RailsPress CMS",
      "groups" => groups
    }
  end

  def build_zip(manifest)
    file = Tempfile.new(["cms_import", ".zip"])
    Zip::File.open(file.path, Zip::File::CREATE) do |zip|
      zip.get_output_stream("content.json") { |f| f.write(JSON.pretty_generate(manifest)) }
    end
    file.rewind
    file
  end

  def build_zip_without_manifest
    file = Tempfile.new(["cms_import", ".zip"])
    Zip::File.open(file.path, Zip::File::CREATE) do |zip|
      zip.get_output_stream("readme.txt") { |f| f.write("no manifest here") }
    end
    file.rewind
    file
  end

  def build_zip_with_content(content_json_text)
    file = Tempfile.new(["cms_import", ".zip"])
    Zip::File.open(file.path, Zip::File::CREATE) do |zip|
      zip.get_output_stream("content.json") { |f| f.write(content_json_text) }
    end
    file.rewind
    file
  end
end
