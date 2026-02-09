require "rails_helper"

RSpec.describe "Railspress::Admin::Tags", type: :request do
  fixtures "railspress/tags"

  describe "GET /admin/tags" do
    it "returns success" do
      get railspress.admin_tags_path
      expect(response).to have_http_status(:success)
    end

    it "displays tags" do
      get railspress.admin_tags_path
      expect(response.body).to include("ruby")
    end
  end

  describe "GET /admin/tags/new" do
    it "returns success" do
      get railspress.new_admin_tag_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/tags" do
    it "creates tag with valid params" do
      expect {
        post railspress.admin_tags_path, params: {
          tag: { name: "newtag" }
        }
      }.to change(Railspress::Tag, :count).by(1)

      expect(response).to redirect_to(railspress.admin_tags_path)
    end

    it "normalizes tag name" do
      post railspress.admin_tags_path, params: {
        tag: { name: "  NEW TAG  " }
      }
      expect(Railspress::Tag.last.name).to eq("new tag")
    end

    it "fails with invalid params" do
      post railspress.admin_tags_path, params: {
        tag: { name: "" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/tags/:id/edit" do
    it "returns success" do
      tag = railspress_tags(:ruby)
      get railspress.edit_admin_tag_path(tag)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/tags/:id" do
    it "updates tag" do
      tag = railspress_tags(:tutorial)
      patch railspress.admin_tag_path(tag), params: {
        tag: { name: "updated" }
      }
      expect(response).to redirect_to(railspress.admin_tags_path)
      expect(tag.reload.name).to eq("updated")
    end

    it "fails with invalid params" do
      tag = railspress_tags(:ruby)
      patch railspress.admin_tag_path(tag), params: {
        tag: { name: "" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /admin/tags/:id" do
    it "deletes tag" do
      tag = railspress_tags(:tutorial)
      expect {
        delete railspress.admin_tag_path(tag)
      }.to change(Railspress::Tag, :count).by(-1)
    end
  end
end
