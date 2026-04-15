# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::Posts", type: :request do
  fixtures "railspress/posts", "railspress/categories", "railspress/tags", "railspress/taggings", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Posts API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }

  before do
    Railspress.configure(&:enable_api)
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

  describe "GET /api/v1/posts" do
    context "without an api key" do
      it "returns unauthorized" do
        get railspress.api_v1_posts_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid api key" do
      it "returns posts with pagination metadata" do
        get railspress.api_v1_posts_path, headers: headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["data"]).to be_an(Array)
        expect(body["meta"]["total_count"]).to be >= 1
      end
    end
  end

  describe "GET /api/v1/posts/:id" do
    it "returns a single post" do
      post_record = railspress_posts(:hello_world)

      get railspress.api_v1_post_path(post_record), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(post_record.id)
    end
  end

  describe "POST /api/v1/posts" do
    it "creates a post with valid params" do
      expect {
        post railspress.api_v1_posts_path,
             headers: headers,
             params: { post: { title: "API Created Post", status: "draft" } }
      }.to change(Railspress::Post, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "title")).to eq("API Created Post")
    end

    it "returns validation errors for invalid params" do
      post railspress.api_v1_posts_path,
           headers: headers,
           params: { post: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("Title can't be blank")
    end

    it "creates a post with author_id when authors are enabled" do
      Railspress.configure do |config|
        config.enable_authors
        config.author_class_name = "User"
        config.author_display_method = :email_address
      end

      expect {
        post railspress.api_v1_posts_path,
             headers: headers,
             params: {
               post: {
                 title: "API Authored Post",
                 status: "draft",
                 author_id: actor.id
               }
             }
      }.to change(Railspress::Post, :count).by(1)

      created_post = Railspress::Post.last
      expect(created_post.author_id).to eq(actor.id)
      expect(response.parsed_body.dig("data", "author_display")).to eq(actor.email_address)
    end

    it "creates a post with a signed header image blob when post images are enabled" do
      Railspress.configure(&:enable_post_images)
      signed_blob_id = create_signed_blob_id

      post railspress.api_v1_posts_path,
           headers: headers,
           params: {
             post: {
               title: "API Image Post",
               status: "draft",
               header_image_signed_blob_id: signed_blob_id
             }
           }

      expect(response).to have_http_status(:created)
      expect(Railspress::Post.last.header_image).to be_attached
      expect(response.parsed_body.dig("data", "header_image", "attached")).to eq(true)
    end

    it "creates a post with the full editor payload" do
      Railspress.configure do |config|
        config.enable_authors
        config.author_class_name = "User"
        config.author_display_method = :email_address
        config.enable_post_images
        config.enable_focal_points
      end

      post railspress.api_v1_posts_path,
           headers: headers,
           params: {
             post: {
               title: "Full Payload Post",
               slug: "full-payload-post",
               status: "published",
               published_at: "2026-04-15T12:30:00Z",
               reading_time: 8,
               meta_title: "Custom Meta Title",
               meta_description: "Custom meta description from API",
               category_id: railspress_categories(:technology).id,
               author_id: actor.id,
               tag_list: "rails, api, full-payload",
               content: "<h2>Full API payload</h2><p>Rich text content.</p>",
               header_image_signed_blob_id: create_signed_blob_id,
               header_image_focal_point_attributes: {
                 focal_x: 0.33,
                 focal_y: 0.61,
                 overrides: {
                   "hero" => { "type" => "focal" }
                 }
               }
             }
           }

      expect(response).to have_http_status(:created)

      created_post = Railspress::Post.order(:id).last
      expect(created_post.slug).to eq("full-payload-post")
      expect(created_post.status).to eq("published")
      expect(created_post.reading_time).to eq(8)
      expect(created_post.meta_title).to eq("Custom Meta Title")
      expect(created_post.meta_description).to eq("Custom meta description from API")
      expect(created_post.category_id).to eq(railspress_categories(:technology).id)
      expect(created_post.author_id).to eq(actor.id)
      expect(created_post.tag_list).to include("rails", "api", "full-payload")
      expect(created_post.header_image).to be_attached
      expect(created_post.header_image_focal_point.focal_x.to_f).to eq(0.33)
      expect(created_post.header_image_focal_point.focal_y.to_f).to eq(0.61)
      expect(created_post.header_image_focal_point.overrides.dig("hero", "type")).to eq("focal")
      expect(response.parsed_body.dig("data", "author_display")).to eq(actor.email_address)
    end
  end

  describe "PATCH /api/v1/posts/:id" do
    it "updates the post" do
      post_record = railspress_posts(:hello_world)

      patch railspress.api_v1_post_path(post_record),
            headers: headers,
            params: { post: { title: "API Updated Title" } }

      expect(response).to have_http_status(:ok)
      expect(post_record.reload.title).to eq("API Updated Title")
    end

    it "returns not found for slug-style ids" do
      patch railspress.api_v1_post_path(id: "hello-world"),
            headers: headers,
            params: { post: { title: "Nope" } }

      expect(response).to have_http_status(:not_found)
    end

    it "removes the header image when remove_header_image is set" do
      Railspress.configure(&:enable_post_images)
      post_record = railspress_posts(:hello_world)
      post_record.header_image.attach(
        io: StringIO.new(File.binread(test_image_path)),
        filename: "test_image.png",
        content_type: "image/png"
      )
      expect(post_record.header_image).to be_attached

      patch railspress.api_v1_post_path(post_record),
            headers: headers,
            params: { post: { remove_header_image: "1" } }

      expect(response).to have_http_status(:ok)
      expect(post_record.reload.header_image).not_to be_attached
    end
  end

  describe "DELETE /api/v1/posts/:id" do
    it "deletes the post" do
      post_record = Railspress::Post.create!(title: "Delete Me", status: :draft)

      expect {
        delete railspress.api_v1_post_path(post_record), headers: headers
      }.to change(Railspress::Post, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "revoked key access" do
    it "returns unauthorized when key is revoked" do
      api_key, token = Railspress::ApiKey.issue!(name: "Temporary Key", actor: actor)
      api_key.revoke!(actor: actor)

      get railspress.api_v1_posts_path, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "bootstrap key access" do
    it "returns unauthorized when using a bootstrap token against content endpoints" do
      _bootstrap_key, bootstrap_token = Railspress::AgentBootstrapKey.issue!(name: "Bootstrap Only", actor: actor)

      get railspress.api_v1_posts_path, headers: { "Authorization" => "Bearer #{bootstrap_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
