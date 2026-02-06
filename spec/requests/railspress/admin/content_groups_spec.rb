# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::ContentGroups", type: :request do
  fixtures "railspress/content_groups", "railspress/content_elements"

  let(:headers_group) { railspress_content_groups(:headers) }
  let(:footers_group) { railspress_content_groups(:footers) }
  let(:deleted_group) { railspress_content_groups(:deleted_group) }

  describe "GET /railspress/admin/content_groups" do
    it "returns a successful response" do
      get railspress.admin_content_groups_path
      expect(response).to have_http_status(:ok)
    end

    it "displays active content groups" do
      get railspress.admin_content_groups_path
      expect(response.body).to include(headers_group.name)
      expect(response.body).to include(footers_group.name)
    end

    it "does not display deleted groups" do
      get railspress.admin_content_groups_path
      expect(response.body).not_to include("Deleted Group")
    end
  end

  describe "GET /railspress/admin/content_groups/:id" do
    it "returns a successful response" do
      get railspress.admin_content_group_path(headers_group)
      expect(response).to have_http_status(:ok)
    end

    it "displays the group name" do
      get railspress.admin_content_group_path(headers_group)
      expect(response.body).to include(headers_group.name)
    end

    it "displays active content elements" do
      get railspress.admin_content_group_path(headers_group)
      headers_group.content_elements.active.each do |element|
        expect(response.body).to include(element.name)
      end
    end

    it "redirects for deleted groups" do
      get railspress.admin_content_group_path(deleted_group)
      expect(response).to redirect_to(railspress.admin_content_groups_path)
    end
  end

  describe "GET /railspress/admin/content_groups/new" do
    it "returns a successful response" do
      get railspress.new_admin_content_group_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /railspress/admin/content_groups" do
    context "with valid params" do
      let(:valid_params) do
        { content_group: { name: "Navigation", description: "Nav items" } }
      end

      it "creates a new content group" do
        expect {
          post railspress.admin_content_groups_path, params: valid_params
        }.to change(Railspress::ContentGroup, :count).by(1)
      end

      it "redirects to the new group" do
        post railspress.admin_content_groups_path, params: valid_params
        new_group = Railspress::ContentGroup.find_by(name: "Navigation")
        expect(response).to redirect_to(railspress.admin_content_group_path(new_group))
      end

      it "sets a flash notice" do
        post railspress.admin_content_groups_path, params: valid_params
        expect(flash[:notice]).to include("Navigation")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { content_group: { name: "", description: "No name" } }
      end

      it "does not create a content group" do
        expect {
          post railspress.admin_content_groups_path, params: invalid_params
        }.not_to change(Railspress::ContentGroup, :count)
      end

      it "returns unprocessable_entity status" do
        post railspress.admin_content_groups_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with duplicate name" do
      let(:duplicate_params) do
        { content_group: { name: headers_group.name } }
      end

      it "does not create a content group" do
        expect {
          post railspress.admin_content_groups_path, params: duplicate_params
        }.not_to change(Railspress::ContentGroup, :count)
      end
    end
  end

  describe "GET /railspress/admin/content_groups/:id/edit" do
    it "returns a successful response" do
      get railspress.edit_admin_content_group_path(headers_group)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /railspress/admin/content_groups/:id" do
    context "with valid params" do
      it "updates the content group" do
        patch railspress.admin_content_group_path(headers_group),
              params: { content_group: { name: "Updated Headers" } }
        expect(headers_group.reload.name).to eq("Updated Headers")
      end

      it "redirects to the group" do
        patch railspress.admin_content_group_path(headers_group),
              params: { content_group: { name: "Updated Headers" } }
        expect(response).to redirect_to(railspress.admin_content_group_path(headers_group))
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity status" do
        patch railspress.admin_content_group_path(headers_group),
              params: { content_group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /railspress/admin/content_groups/:id" do
    it "soft deletes the content group" do
      delete railspress.admin_content_group_path(headers_group)
      expect(headers_group.reload.deleted?).to be true
    end

    it "does not permanently destroy the record" do
      expect {
        delete railspress.admin_content_group_path(headers_group)
      }.not_to change(Railspress::ContentGroup, :count)
    end

    it "redirects to the index" do
      delete railspress.admin_content_group_path(headers_group)
      expect(response).to redirect_to(railspress.admin_content_groups_path)
    end

    it "cascades soft delete to content elements" do
      delete railspress.admin_content_group_path(headers_group)
      headers_group.content_elements.reload.each do |element|
        expect(element.deleted?).to be true
      end
    end
  end
end
