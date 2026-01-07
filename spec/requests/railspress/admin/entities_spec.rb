# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::Entities", type: :request do
  before do
    Railspress.reset_configuration!
    Railspress.configure do |config|
      config.register_entity Project
    end
  end

  after do
    Railspress.reset_configuration!
  end

  let!(:project) { Project.create!(title: "Test Project", client: "Acme Corp", featured: true) }

  describe "GET /admin/entities/projects" do
    it "returns success" do
      get railspress.admin_entity_index_path(entity_type: "projects")
      expect(response).to have_http_status(:success)
    end

    it "displays entity label in title" do
      get railspress.admin_entity_index_path(entity_type: "projects")
      expect(response.body).to include("Client Projects")
    end

    it "displays records" do
      get railspress.admin_entity_index_path(entity_type: "projects")
      expect(response.body).to include("Test Project")
      expect(response.body).to include("Acme Corp")
    end
  end

  describe "GET /admin/entities/projects/new" do
    it "returns success" do
      get railspress.admin_new_entity_path(entity_type: "projects")
      expect(response).to have_http_status(:success)
    end

    it "displays form with fields" do
      get railspress.admin_new_entity_path(entity_type: "projects")
      expect(response.body).to include("Title")
      expect(response.body).to include("Client")
    end
  end

  describe "POST /admin/entities/projects" do
    let(:valid_params) do
      { project: { title: "New Project", client: "New Client", featured: false } }
    end

    let(:invalid_params) do
      { project: { title: "", client: "Client" } }
    end

    it "creates record with valid params" do
      expect {
        post railspress.admin_entity_index_path(entity_type: "projects"), params: valid_params
      }.to change(Project, :count).by(1)
    end

    it "redirects after creation" do
      post railspress.admin_entity_index_path(entity_type: "projects"), params: valid_params
      expect(response).to redirect_to(railspress.admin_entity_index_path(entity_type: "projects"))
    end

    it "fails with invalid params" do
      post railspress.admin_entity_index_path(entity_type: "projects"), params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/entities/projects/:id" do
    it "returns success" do
      get railspress.admin_entity_path(entity_type: "projects", id: project.id)
      expect(response).to have_http_status(:success)
    end

    it "displays record details" do
      get railspress.admin_entity_path(entity_type: "projects", id: project.id)
      expect(response.body).to include("Test Project")
      expect(response.body).to include("Acme Corp")
    end
  end

  describe "GET /admin/entities/projects/:id/edit" do
    it "returns success" do
      get railspress.admin_edit_entity_path(entity_type: "projects", id: project.id)
      expect(response).to have_http_status(:success)
    end

    it "displays form with existing values" do
      get railspress.admin_edit_entity_path(entity_type: "projects", id: project.id)
      expect(response.body).to include("Test Project")
    end
  end

  describe "PATCH /admin/entities/projects/:id" do
    it "updates record" do
      patch railspress.admin_entity_path(entity_type: "projects", id: project.id),
            params: { project: { title: "Updated Title" } }

      project.reload
      expect(project.title).to eq("Updated Title")
    end

    it "redirects after update" do
      patch railspress.admin_entity_path(entity_type: "projects", id: project.id),
            params: { project: { title: "Updated Title" } }

      expect(response).to redirect_to(railspress.admin_entity_index_path(entity_type: "projects"))
    end

    it "fails with invalid params" do
      patch railspress.admin_entity_path(entity_type: "projects", id: project.id),
            params: { project: { title: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/entities/projects/:id" do
    it "deletes record" do
      expect {
        delete railspress.admin_entity_path(entity_type: "projects", id: project.id)
      }.to change(Project, :count).by(-1)
    end

    it "redirects after deletion" do
      delete railspress.admin_entity_path(entity_type: "projects", id: project.id)
      expect(response).to redirect_to(railspress.admin_entity_index_path(entity_type: "projects"))
    end
  end

  describe "unregistered entity" do
    it "returns 404 for unknown entity type" do
      # The route constraint prevents matching, which Rails handles as 404
      get "/railspress/admin/entities/unknown"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/entities/projects/:id/image_editor/:attachment (Entity image editor)" do
    let(:image_path) { Rails.root.join("../../spec/fixtures/files/test_image.png") }
    let(:project_with_image) do
      project.main_image.attach(
        io: File.open(image_path),
        filename: "test_image.png",
        content_type: "image/png"
      )
      # Access focal point to trigger auto-build, then save to persist
      project.main_image_focal_point
      project.save!
      project.reload
    end

    it "returns turbo-frame wrapped editor content" do
      project_with_image # ensure image is attached

      get railspress.admin_entity_image_editor_path(
        entity_type: "projects",
        id: project.id,
        attachment: :main_image
      )

      expect(response).to have_http_status(:success)
      expect(response.body).to include("<turbo-frame")
      expect(response.body).to include("image_section_main_image")
    end

    it "returns turbo-frame wrapped compact view when compact=true" do
      project_with_image # ensure image is attached

      get railspress.admin_entity_image_editor_path(
        entity_type: "projects",
        id: project.id,
        attachment: :main_image,
        compact: true
      )

      expect(response).to have_http_status(:success)
      expect(response.body).to include("<turbo-frame")
      expect(response.body).to include("image_section_main_image")
    end
  end
end
