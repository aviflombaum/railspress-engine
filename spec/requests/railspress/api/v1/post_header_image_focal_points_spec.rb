# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::PostHeaderImageFocalPoints", type: :request do
  fixtures "railspress/posts", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Post Focal Point API", actor: actor).last }
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

  def attach_header_image(record)
    record.header_image.attach(
      io: StringIO.new(File.binread(test_image_path)),
      filename: "test_image.png",
      content_type: "image/png"
    )
  end

  describe "GET /api/v1/posts/:post_id/header_image/focal_point" do
    it "returns focal point data when header image is attached" do
      attach_header_image(post_record)

      get railspress.api_v1_post_header_image_focal_point_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "focal_x")).to eq(0.5)
      expect(response.parsed_body.dig("data", "focal_y")).to eq(0.5)
    end

    it "returns validation error when header image is not attached" do
      get railspress.api_v1_post_header_image_focal_point_path(post_record), headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to eq("Header image is not attached.")
    end
  end

  describe "PATCH /api/v1/posts/:post_id/header_image/focal_point" do
    it "updates focal point coordinates and overrides" do
      attach_header_image(post_record)

      patch railspress.api_v1_post_header_image_focal_point_path(post_record),
            headers: headers,
            params: {
              focal_point: {
                focal_x: 0.2,
                focal_y: 0.7,
                overrides: {
                  "hero" => { "type" => "focal" }
                }
              }
            }

      expect(response).to have_http_status(:ok)
      post_record.reload
      focal_point = post_record.header_image_focal_point
      expect(focal_point.focal_x.to_f).to eq(0.2)
      expect(focal_point.focal_y.to_f).to eq(0.7)
      expect(focal_point.overrides.dig("hero", "type")).to eq("focal")
    end

    it "returns validation errors for out-of-range coordinates" do
      attach_header_image(post_record)

      patch railspress.api_v1_post_header_image_focal_point_path(post_record),
            headers: headers,
            params: { focal_point: { focal_x: 2.0, focal_y: -1.0 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("Focal x must be less than or equal to 1")
    end

    it "returns not found when focal points are disabled" do
      allow(Railspress).to receive(:focal_points_enabled?).and_return(false)

      attach_header_image(post_record)

      patch railspress.api_v1_post_header_image_focal_point_path(post_record),
            headers: headers,
            params: { focal_point: { focal_x: 0.4, focal_y: 0.4 } }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "message")).to eq("Focal points are not enabled.")
    end
  end
end
