require "rails_helper"

RSpec.describe "Railspress::Admin::Posts", type: :request do
  fixtures "railspress/categories", "railspress/tags", "railspress/posts", "railspress/post_tags"

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
end
