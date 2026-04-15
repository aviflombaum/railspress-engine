# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::PostImports", type: :request do
  fixtures :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Post Imports API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }

  before do
    Railspress.configure(&:enable_api)
    allow(Railspress::ImportPostsJob).to receive(:perform_later)
  end

  def markdown_fixture_path
    Rails.root.join("../../spec/fixtures/files/valid_post.md")
  end

  describe "POST /api/v1/posts/imports" do
    it "queues a markdown upload import" do
      file = Rack::Test::UploadedFile.new(markdown_fixture_path, "text/markdown")

      post railspress.api_v1_post_imports_path,
           headers: headers,
           params: { file: file }

      expect(response).to have_http_status(:accepted)
      import = Railspress::Import.order(:id).last
      expect(import.import_type).to eq("posts")
      expect(import.filename).to eq("valid_post.md")
      expect(import.user_id).to eq(actor.id)
      expect(Railspress::ImportPostsJob).to have_received(:perform_later).with(import.id, [ kind_of(String) ])
    end

    it "queues an import from a signed blob id" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(File.binread(markdown_fixture_path)),
        filename: "from_blob.md",
        content_type: "text/markdown"
      )

      post railspress.api_v1_post_imports_path,
           headers: headers,
           params: { signed_blob_id: blob.signed_id }

      expect(response).to have_http_status(:accepted)
      import = Railspress::Import.order(:id).last
      expect(import.filename).to eq("from_blob.md")
      expect(Railspress::ImportPostsJob).to have_received(:perform_later).with(import.id, [ kind_of(String) ])
    end

    it "returns a validation error when no file source is provided" do
      post railspress.api_v1_post_imports_path, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq("Either file or signed_blob_id is required.")
    end

    it "returns a validation error for unsupported file types" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("../../spec/fixtures/files/test_image.png"), "image/png")

      post railspress.api_v1_post_imports_path,
           headers: headers,
           params: { file: file }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to include("Unsupported import file type")
    end
  end

  describe "GET /api/v1/posts/imports/:id" do
    it "returns import status and counts" do
      import = Railspress::Import.create!(
        import_type: "posts",
        filename: "valid_post.md",
        content_type: "text/markdown",
        status: "processing",
        total_count: 1,
        success_count: 0,
        error_count: 0
      )

      get railspress.api_v1_post_import_path(import), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(import.id)
      expect(response.parsed_body.dig("data", "status")).to eq("processing")
      expect(response.parsed_body.dig("data", "total_count")).to eq(1)
    end
  end
end
