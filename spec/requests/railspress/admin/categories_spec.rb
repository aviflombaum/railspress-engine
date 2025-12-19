require "rails_helper"

RSpec.describe "Railspress::Admin::Categories", type: :request do
  fixtures "railspress/categories", "railspress/posts"

  describe "GET /admin/categories" do
    it "returns success" do
      get railspress.admin_categories_path
      expect(response).to have_http_status(:success)
    end

    it "displays categories" do
      get railspress.admin_categories_path
      expect(response.body).to include("Technology")
    end
  end

  describe "GET /admin/categories/new" do
    it "returns success" do
      get railspress.new_admin_category_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/categories" do
    it "creates category with valid params" do
      expect {
        post railspress.admin_categories_path, params: {
          category: { name: "New Category", description: "Test" }
        }
      }.to change(Railspress::Category, :count).by(1)

      expect(response).to redirect_to(railspress.admin_categories_path)
    end

    it "fails with invalid params" do
      post railspress.admin_categories_path, params: {
        category: { name: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/categories/:id/edit" do
    it "returns success" do
      category = railspress_categories(:technology)
      get railspress.edit_admin_category_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/categories/:id" do
    it "updates category" do
      category = railspress_categories(:technology)
      patch railspress.admin_category_path(category), params: {
        category: { name: "Updated Name" }
      }
      expect(response).to redirect_to(railspress.admin_categories_path)
      expect(category.reload.name).to eq("Updated Name")
    end

    it "fails with invalid params" do
      category = railspress_categories(:technology)
      patch railspress.admin_category_path(category), params: {
        category: { name: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/categories/:id" do
    it "deletes category without posts" do
      category = Railspress::Category.create!(name: "Empty Category")
      expect {
        delete railspress.admin_category_path(category)
      }.to change(Railspress::Category, :count).by(-1)
    end

    it "cannot delete category with posts" do
      category = railspress_categories(:technology)
      expect {
        delete railspress.admin_category_path(category)
      }.not_to change(Railspress::Category, :count)
    end
  end
end
