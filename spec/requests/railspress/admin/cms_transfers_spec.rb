# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe "Railspress::Admin::CmsTransfers", type: :request do
  fixtures "railspress/content_groups", "railspress/content_elements"

  describe "GET /railspress/admin/cms_transfer" do
    it "returns a successful response" do
      get railspress.admin_cms_transfer_path
      expect(response).to have_http_status(:ok)
    end

    it "displays export section" do
      get railspress.admin_cms_transfer_path
      expect(response.body).to include("Export Content")
      expect(response.body).to include("Export All Content")
    end

    it "displays import section" do
      get railspress.admin_cms_transfer_path
      expect(response.body).to include("Import Content")
    end

    it "shows content summary counts" do
      get railspress.admin_cms_transfer_path
      expect(response.body).to include("Groups")
      expect(response.body).to include("Elements")
    end
  end

  describe "POST /railspress/admin/cms_transfer/export" do
    it "returns a ZIP file" do
      post railspress.export_admin_cms_transfer_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/zip")
    end

    it "sets a content-disposition header with filename" do
      post railspress.export_admin_cms_transfer_path
      expect(response.headers["Content-Disposition"]).to match(/cms_content_\d{8}_\d{6}\.zip/)
    end

    it "produces a valid ZIP with content.json" do
      post railspress.export_admin_cms_transfer_path
      entries = []
      Zip::InputStream.open(StringIO.new(response.body)) do |zip|
        while (entry = zip.get_next_entry)
          entries << entry.name
        end
      end
      expect(entries).to include("content.json")
    end
  end

  describe "POST /railspress/admin/cms_transfer/import" do
    it "redirects with alert when no file provided" do
      post railspress.import_admin_cms_transfer_path
      expect(response).to redirect_to(railspress.admin_cms_transfer_path)
      follow_redirect!
      expect(response.body).to include("Please select a ZIP file")
    end

    it "imports valid ZIP and shows results" do
      zip = build_import_zip(groups: [
        { "name" => "Imported Group", "description" => "From import", "elements" => [
          { "name" => "Imported Element", "content_type" => "text", "position" => 1, "text_content" => "Hello" }
        ] }
      ])

      post railspress.import_admin_cms_transfer_path, params: { file: zip }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Created")
      expect(Railspress::ContentGroup.find_by(name: "Imported Group")).to be_present
    end

    it "shows errors for invalid ZIP" do
      invalid_file = Rack::Test::UploadedFile.new(
        StringIO.new("not a zip"), "application/zip", false, original_filename: "bad.zip"
      )

      post railspress.import_admin_cms_transfer_path, params: { file: invalid_file }
      expect(response).to redirect_to(railspress.admin_cms_transfer_path)
    end

    it "handles ZIP without content.json" do
      file = Tempfile.new(["no_manifest", ".zip"])
      Zip::File.open(file.path, Zip::File::CREATE) do |zip|
        zip.get_output_stream("readme.txt") { |f| f.write("no manifest") }
      end
      file.rewind

      upload = Rack::Test::UploadedFile.new(file.path, "application/zip")
      post railspress.import_admin_cms_transfer_path, params: { file: upload }
      expect(response).to redirect_to(railspress.admin_cms_transfer_path)
    end
  end

  private

  def build_import_zip(groups:)
    manifest = {
      "version" => 1,
      "exported_at" => Time.current.iso8601,
      "source" => "RailsPress CMS",
      "groups" => groups
    }

    file = Tempfile.new(["cms_import", ".zip"])
    Zip::File.open(file.path, Zip::File::CREATE) do |zip|
      zip.get_output_stream("content.json") { |f| f.write(JSON.pretty_generate(manifest)) }
    end
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "application/zip")
  end
end
