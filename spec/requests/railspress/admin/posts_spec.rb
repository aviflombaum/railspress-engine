require "rails_helper"

RSpec.describe "Railspress::Admin::Posts", type: :request do
  fixtures "railspress/categories", "railspress/tags", "railspress/posts", "railspress/taggings"

  let(:category) { railspress_categories(:technology) }

  describe "GET /admin/posts" do
    it "returns success" do
      get railspress.admin_posts_path
      expect(response).to have_http_status(:success)
    end

    it "displays posts" do
      get railspress.admin_posts_path
      expect(response.body).to include("Hello World")
    end
  end

  describe "GET /admin/posts/:id" do
    it "returns success" do
      post = railspress_posts(:hello_world)
      get railspress.admin_post_path(post)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/posts/new" do
    it "returns success" do
      get railspress.new_admin_post_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/posts" do
    it "creates post with valid params" do
      expect {
        post railspress.admin_posts_path, params: {
          post: { title: "New Post", status: "draft" }
        }
      }.to change(Railspress::Post, :count).by(1)

      expect(response).to redirect_to(railspress.admin_post_path(Railspress::Post.last))
    end

    it "creates post with category" do
      post railspress.admin_posts_path, params: {
        post: {
          title: "Categorized Post",
          category_id: category.id,
          status: "draft"
        }
      }
      expect(Railspress::Post.last.category).to eq(category)
    end

    it "creates post with tags" do
      post railspress.admin_posts_path, params: {
        post: {
          title: "Tagged Post",
          tag_list: "ruby, rails, testing"
        }
      }

      created_post = Railspress::Post.last
      expect(created_post.tags.count).to eq(3)
    end

    it "fails with invalid params" do
      post railspress.admin_posts_path, params: {
        post: { title: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/posts/:id/edit" do
    it "returns success" do
      post_record = railspress_posts(:hello_world)
      get railspress.edit_admin_post_path(post_record)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/posts/:id" do
    it "updates post" do
      post_record = railspress_posts(:hello_world)
      patch railspress.admin_post_path(post_record), params: {
        post: { title: "Updated Title" }
      }
      expect(response).to redirect_to(railspress.admin_post_path(post_record))
      expect(post_record.reload.title).to eq("Updated Title")
    end

    it "updates tags" do
      post_record = railspress_posts(:hello_world)
      patch railspress.admin_post_path(post_record), params: {
        post: { tag_list: "newtag1, newtag2" }
      }
      expect(post_record.reload.tags.count).to eq(2)
    end

    it "fails with invalid params" do
      post_record = railspress_posts(:hello_world)
      patch railspress.admin_post_path(post_record), params: {
        post: { title: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/posts/:id" do
    it "deletes post" do
      post_record = railspress_posts(:draft_post)
      expect {
        delete railspress.admin_post_path(post_record)
      }.to change(Railspress::Post, :count).by(-1)
    end
  end

  describe "header image uploads", type: :request do
    let(:image_path) { Rails.root.join("../../spec/fixtures/files/test_image.png") }
    let(:image_file) { Rack::Test::UploadedFile.new(image_path, "image/png") }

    before do
      Railspress.configure { |c| c.enable_post_images }
    end

    after do
      Railspress.reset_configuration!
    end

    it "uploads header image on create" do
      post railspress.admin_posts_path, params: {
        post: {
          title: "Post with Image",
          header_image: image_file
        }
      }

      created_post = Railspress::Post.last
      expect(created_post.header_image).to be_attached
    end

    it "uploads header image on update" do
      post_record = railspress_posts(:draft_post)
      patch railspress.admin_post_path(post_record), params: {
        post: { header_image: image_file }
      }

      expect(post_record.reload.header_image).to be_attached
    end

    it "removes header image when checkbox is checked" do
      post_record = railspress_posts(:draft_post)
      post_record.header_image.attach(
        io: File.open(image_path),
        filename: "test.png",
        content_type: "image/png"
      )
      expect(post_record.header_image).to be_attached

      patch railspress.admin_post_path(post_record), params: {
        post: { remove_header_image: "1" }
      }

      expect(post_record.reload.header_image).not_to be_attached
    end

    it "displays featured image on show page" do
      post_record = railspress_posts(:hello_world)
      post_record.header_image.attach(
        io: File.open(image_path),
        filename: "test.png",
        content_type: "image/png"
      )

      get railspress.admin_post_path(post_record)
      expect(response.body).to include("rp-image-section")
    end

    it "re-renders form with validation errors when create fails with header image" do
      # First, create a post to cause a slug collision
      existing_post = railspress_posts(:hello_world)

      # Try to create another post with same slug and a header image
      post railspress.admin_posts_path, params: {
        post: {
          title: "Different Title",
          slug: existing_post.slug, # duplicate slug should fail validation
          header_image: image_file
        }
      }

      # Should re-render form with validation errors, not crash
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("has already been taken")
    end

    it "re-renders form with validation errors when update fails with header image" do
      post_record = railspress_posts(:draft_post)
      existing_post = railspress_posts(:hello_world)

      # Try to update with duplicate slug and a header image
      patch railspress.admin_post_path(post_record), params: {
        post: {
          slug: existing_post.slug, # duplicate slug should fail validation
          header_image: image_file
        }
      }

      # Should re-render form with validation errors, not crash
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("has already been taken")
    end
  end

  describe "GET /admin/posts/:id/image_editor/:attachment" do
    let(:image_path) { Rails.root.join("../../spec/fixtures/files/test_image.png") }

    it "returns expanded editor partial" do
      post_record = railspress_posts(:hello_world)
      post_record.header_image.attach(
        io: File.open(image_path),
        filename: "test_image.png",
        content_type: "image/png"
      )
      # Access focal point to trigger auto-build, then save to persist
      post_record.header_image_focal_point
      post_record.save!

      get railspress.image_editor_admin_post_path(post_record, attachment: :header_image)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("rp-image-section__editor")
      expect(response.body).to include("turbo-frame")
    end

    it "returns compact partial when compact=true" do
      post_record = railspress_posts(:hello_world)
      post_record.header_image.attach(
        io: File.open(image_path),
        filename: "test_image.png",
        content_type: "image/png"
      )
      # Access focal point to trigger auto-build, then save to persist
      post_record.header_image_focal_point
      post_record.save!

      get railspress.image_editor_admin_post_path(post_record, attachment: :header_image, compact: "true")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("rp-image-section__compact")
      expect(response.body).not_to include("rp-image-section--editing")
    end
  end
end
