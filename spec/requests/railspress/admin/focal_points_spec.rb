# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::FocalPoints", type: :request do
  fixtures "railspress/posts", "railspress/categories", "railspress/focal_points"

  let(:image_path) { Rails.root.join("../../spec/fixtures/files/test_image.png") }
  let(:post_record) do
    post = railspress_posts(:hello_world)
    post.header_image.attach(
      io: File.open(image_path),
      filename: "test_image.png",
      content_type: "image/png"
    )
    # Access focal point to trigger auto-build, then save to persist
    post.header_image_focal_point
    post.save!
    post.reload
  end
  let(:focal_point) { post_record.header_image_focal_point }

  describe "GET /admin/posts/:id/image_editor (Post image editor)" do
    it "returns turbo-frame wrapped editor content" do
      get railspress.image_editor_admin_post_path(post_record, attachment: :header_image)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("<turbo-frame")
      expect(response.body).to include("image_section_header_image")
    end

    it "returns turbo-frame wrapped compact view when compact=true" do
      get railspress.image_editor_admin_post_path(post_record, attachment: :header_image, compact: true)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("<turbo-frame")
      expect(response.body).to include("image_section_header_image")
    end
  end

  describe "PATCH /admin/focal_points/:id" do
    it "updates focal point values" do
      patch railspress.admin_focal_point_path(focal_point), params: {
        focal_point: { focal_x: 0.25, focal_y: 0.75 }
      }

      focal_point.reload
      expect(focal_point.focal_x).to eq(0.25)
      expect(focal_point.focal_y).to eq(0.75)
    end

    it "responds with turbo stream when requested" do
      patch railspress.admin_focal_point_path(focal_point),
            params: { focal_point: { focal_x: 0.3, focal_y: 0.7 } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end

    it "redirects to edit page on HTML request" do
      patch railspress.admin_focal_point_path(focal_point),
            params: { focal_point: { focal_x: 0.5, focal_y: 0.5 } }

      expect(response).to redirect_to(railspress.edit_admin_post_path(post_record))
    end

    it "handles image change" do
      new_image = Rack::Test::UploadedFile.new(image_path, "image/png")
      original_blob_id = post_record.header_image.blob.id

      patch railspress.admin_focal_point_path(focal_point),
            params: {
              image: new_image,
              focal_point: { focal_x: 0.5, focal_y: 0.5 }
            }

      expect(response).to redirect_to(railspress.edit_admin_post_path(post_record))
      post_record.reload
      expect(post_record.header_image).to be_attached
      # New blob should have been created
      expect(post_record.header_image.blob.id).not_to eq(original_blob_id)
    end

    it "handles image removal" do
      expect(post_record.header_image).to be_attached

      patch railspress.admin_focal_point_path(focal_point),
            params: {
              remove_image: "1",
              focal_point: { focal_x: 0.5, focal_y: 0.5 }
            }

      expect(response).to redirect_to(railspress.edit_admin_post_path(post_record))
      post_record.reload
      expect(post_record.header_image).not_to be_attached
    end
  end
end
