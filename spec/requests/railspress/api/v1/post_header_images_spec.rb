# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::PostHeaderImages", type: :request do
  fixtures "railspress/posts", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Post Header Image API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }
  let(:post_record) { railspress_posts(:hello_world) }

  before do
    Railspress.configure do |config|
      config.enable_api
      config.enable_post_images
      config.enable_focal_points
    end
  end

  def test_image_path
    Rails.root.join("../../spec/fixtures/files/test_image.png")
  end

  def create_signed_blob_id
    data = File.binread(test_image_path)
    ActiveStorage::Blob
      .create_and_upload!(io: StringIO.new(data), filename: "test_image.png", content_type: "image/png")
      .signed_id
  end

  describe "PUT /api/v1/posts/:post_id/header_image" do
    it "attaches a header image from signed_blob_id" do
      put railspress.api_v1_post_header_image_path(post_record),
          headers: headers,
          params: { signed_blob_id: create_signed_blob_id }

      expect(response).to have_http_status(:ok)
      expect(post_record.reload.header_image).to be_attached
      expect(response.parsed_body.dig("data", "header_image", "attached")).to eq(true)
    end

    it "returns validation error when image params are missing" do
      put railspress.api_v1_post_header_image_path(post_record), headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to include("Either image or signed_blob_id is required")
    end

    it "returns validation error for invalid signed_blob_id" do
      put railspress.api_v1_post_header_image_path(post_record),
          headers: headers,
          params: { signed_blob_id: "bad-signed-id" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq("Invalid signed blob id.")
    end
  end

  describe "GET /api/v1/posts/:post_id/header_image" do
    it "returns header image metadata" do
      post_record.header_image.attach(
        io: StringIO.new(File.binread(test_image_path)),
        filename: "test_image.png",
        content_type: "image/png"
      )

      get railspress.api_v1_post_header_image_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "header_image", "attached")).to eq(true)
    end

    it "returns not found when no header image is attached" do
      get railspress.api_v1_post_header_image_path(post_record), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "message")).to eq("Header image not found.")
    end
  end

  describe "DELETE /api/v1/posts/:post_id/header_image" do
    it "purges the attached header image" do
      post_record.header_image.attach(
        io: StringIO.new(File.binread(test_image_path)),
        filename: "test_image.png",
        content_type: "image/png"
      )
      expect(post_record.header_image).to be_attached

      delete railspress.api_v1_post_header_image_path(post_record), headers: headers

      expect(response).to have_http_status(:no_content)
      expect(post_record.reload.header_image).not_to be_attached
    end
  end
end
