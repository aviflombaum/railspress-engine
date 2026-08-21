# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::PostAssets", type: :request do
  fixtures :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Post Assets API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }

  before do
    Railspress.configure(&:enable_api)
  end

  def test_image_path
    Rails.root.join("../../spec/fixtures/files/test_image.png")
  end

  describe "POST /api/v1/post_assets" do
    it "returns canonical Action Text markup for an uploaded image" do
      image = Rack::Test::UploadedFile.new(test_image_path, "image/png")

      post railspress.api_v1_post_assets_path,
           headers: headers,
           params: { image: image }

      expect(response).to have_http_status(:created)
      data = response.parsed_body.fetch("data")
      expect(data.fetch("content_type")).to eq("image/png")
      expect(data.fetch("signed_blob_id")).to be_present
      expect(data.fetch("attachable_sgid")).to be_present
      expect(data.fetch("attachment_html")).to include(
        "<action-text-attachment",
        %(sgid="#{data.fetch("attachable_sgid")}")
      )
    end

    it "returns markup for an existing signed blob" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(File.binread(test_image_path)),
        filename: "existing.png",
        content_type: "image/png"
      )

      post railspress.api_v1_post_assets_path,
           headers: headers,
           params: { signed_blob_id: blob.signed_id }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "blob_id")).to eq(blob.id)
    end

    it "returns a validation error when no image is provided" do
      post railspress.api_v1_post_assets_path, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to include("Either image or signed_blob_id")
    end

    it "returns a validation error for an invalid signed blob id" do
      post railspress.api_v1_post_assets_path,
           headers: headers,
           params: { signed_blob_id: "invalid" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq("Invalid signed blob id.")
    end

    it "rejects unsupported file types" do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join("../../spec/fixtures/files/valid_post.md"),
        "text/markdown"
      )

      post railspress.api_v1_post_assets_path,
           headers: headers,
           params: { image: file }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to include("Unsupported image type")
    end

    it "requires an API key" do
      image = Rack::Test::UploadedFile.new(test_image_path, "image/png")

      post railspress.api_v1_post_assets_path, params: { image: image }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
