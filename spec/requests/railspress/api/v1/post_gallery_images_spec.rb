# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::PostGalleryImages", type: :request do
  fixtures "railspress/categories", "railspress/posts", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Post Gallery Images API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }
  let(:post_record) { railspress_posts(:hello_world) }

  before do
    Railspress.configure do |config|
      config.enable_api
      config.enable_post_images
    end
  end

  def test_image_path
    Rails.root.join("../../spec/fixtures/files/test_image.png")
  end

  def create_blob(filename: "gallery.png")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(File.binread(test_image_path)),
      filename: filename,
      content_type: "image/png"
    )
  end

  describe "POST /api/v1/posts/:post_id/gallery_images" do
    it "attaches an uploaded gallery image" do
      image = Rack::Test::UploadedFile.new(test_image_path, "image/png")

      expect {
        post railspress.api_v1_post_gallery_images_path(post_record),
             headers: headers,
             params: { image: image }
      }.to change(post_record.gallery_images.attachments, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "content_type")).to eq("image/png")
      expect(response.parsed_body.dig("data", "id")).to be_present
    end

    it "attaches a gallery image from a signed blob" do
      blob = create_blob(filename: "signed-gallery.png")

      post railspress.api_v1_post_gallery_images_path(post_record),
           headers: headers,
           params: { signed_blob_id: blob.signed_id }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "blob_id")).to eq(blob.id)
    end

    it "returns not found when post images are disabled" do
      allow(Railspress).to receive(:post_images_enabled?).and_return(false)

      post railspress.api_v1_post_gallery_images_path(post_record),
           headers: headers,
           params: { signed_blob_id: create_blob.signed_id }

      expect(response).to have_http_status(:not_found)
    end

    it "returns a validation error for an invalid signed blob id" do
      post railspress.api_v1_post_gallery_images_path(post_record),
           headers: headers,
           params: { signed_blob_id: "invalid" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq("Invalid signed blob id.")
    end
  end

  describe "GET /api/v1/posts/:post_id/gallery_images" do
    it "returns gallery image metadata" do
      post_record.gallery_images.attach(create_blob)
      attachment = post_record.gallery_images.attachments.last

      get railspress.api_v1_post_gallery_images_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        a_hash_including("id" => attachment.id, "filename" => "gallery.png")
      )
    end

    it "includes gallery images in the post JSON response" do
      post_record.gallery_images.attach(create_blob)

      get railspress.api_v1_post_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "gallery_images")).to include(
        a_hash_including("filename" => "gallery.png")
      )
    end
  end

  describe "DELETE /api/v1/posts/:post_id/gallery_images/:id" do
    it "purges a gallery image" do
      post_record.gallery_images.attach(create_blob)
      attachment = post_record.gallery_images.attachments.last

      delete railspress.api_v1_post_gallery_image_path(post_record, attachment), headers: headers

      expect(response).to have_http_status(:no_content)
      expect(post_record.reload.gallery_images).not_to be_attached
    end

    it "does not delete an attachment belonging to another post" do
      other_post = railspress_posts(:draft_post)
      other_post.gallery_images.attach(create_blob(filename: "other.png"))
      attachment = other_post.gallery_images.attachments.last

      delete railspress.api_v1_post_gallery_image_path(post_record, attachment), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(other_post.reload.gallery_images).to be_attached
    end
  end
end
