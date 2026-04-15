# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::PostHeaderImageContexts", type: :request do
  fixtures "railspress/posts", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Post Header Image Context API", actor: actor).last }
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
      .create_and_upload!(io: StringIO.new(data), filename: "override_image.png", content_type: "image/png")
      .signed_id
  end

  def attach_header_image(record)
    record.header_image.attach(
      io: StringIO.new(File.binread(test_image_path)),
      filename: "header_image.png",
      content_type: "image/png"
    )
  end

  describe "GET /api/v1/posts/:post_id/header_image/contexts" do
    it "returns configured contexts" do
      attach_header_image(post_record)

      get railspress.api_v1_post_header_image_contexts_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        a_hash_including("name" => "hero"),
        a_hash_including("name" => "card")
      )
    end
  end

  describe "GET /api/v1/posts/:post_id/header_image/contexts/:context" do
    it "returns details for a single context" do
      attach_header_image(post_record)

      get railspress.api_v1_post_header_image_context_path(post_record, :hero), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "name")).to eq("hero")
      expect(response.parsed_body.dig("data", "override", "type")).to eq("focal")
    end

    it "returns not found for unknown context" do
      attach_header_image(post_record)

      get railspress.api_v1_post_header_image_context_path(post_record, :missing), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "message")).to eq("Image context not found.")
    end
  end

  describe "PATCH /api/v1/posts/:post_id/header_image/contexts/:context" do
    it "sets crop overrides" do
      attach_header_image(post_record)

      patch railspress.api_v1_post_header_image_context_path(post_record, :hero),
            headers: headers,
            params: {
              override: {
                type: "crop",
                region: { x: 0.1, y: 0.2, width: 0.5, height: 0.6 }
              }
            }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "override", "type")).to eq("crop")
      expect(post_record.reload.image_override(:hero, :header_image).dig(:region, :x)).to eq(0.1)
    end

    it "sets upload overrides with a signed blob" do
      attach_header_image(post_record)

      patch railspress.api_v1_post_header_image_context_path(post_record, :card),
            headers: headers,
            params: {
              override: {
                type: "upload",
                signed_blob_id: create_signed_blob_id
              }
            }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "override", "type")).to eq("upload")
      expect(response.parsed_body.dig("data", "image", "source")).to eq("upload_override")
      expect(post_record.reload.image_override(:card, :header_image).dig(:type)).to eq("upload")
    end

    it "returns validation errors for invalid crop geometry" do
      attach_header_image(post_record)

      patch railspress.api_v1_post_header_image_context_path(post_record, :hero),
            headers: headers,
            params: {
              override: {
                type: "crop",
                region: { x: 0.8, y: 0.2, width: 0.4, height: 0.6 }
              }
            }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq("Crop region must fit within the source image bounds.")
    end
  end

  describe "DELETE /api/v1/posts/:post_id/header_image/contexts/:context" do
    it "clears the custom override and reverts to focal" do
      attach_header_image(post_record)
      post_record.set_image_override(:hero, { type: "crop", region: { x: 0.1, y: 0.1, width: 0.8, height: 0.8 } }, :header_image)
      post_record.save!

      delete railspress.api_v1_post_header_image_context_path(post_record, :hero), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "override", "type")).to eq("focal")
      expect(post_record.reload.has_image_override?(:hero, :header_image)).to eq(false)
    end
  end
end
