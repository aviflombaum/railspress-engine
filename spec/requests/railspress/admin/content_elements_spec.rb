# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::ContentElements", type: :request do
  fixtures "railspress/content_groups", "railspress/content_elements", "railspress/content_element_versions"

  let(:headers_group) { railspress_content_groups(:headers) }
  let(:footers_group) { railspress_content_groups(:footers) }
  let(:homepage_h1) { railspress_content_elements(:homepage_h1) }
  let(:tagline) { railspress_content_elements(:tagline) }
  let(:footer_text) { railspress_content_elements(:footer_text) }
  let(:deleted_element) { railspress_content_elements(:deleted_element) }
  let(:required_element) { railspress_content_elements(:required_element) }

  describe "GET /railspress/admin/content_elements" do
    it "returns a successful response" do
      get railspress.admin_content_elements_path
      expect(response).to have_http_status(:ok)
    end

    it "displays active content elements" do
      get railspress.admin_content_elements_path
      expect(response.body).to include(homepage_h1.name)
      expect(response.body).to include(tagline.name)
    end

    it "does not display deleted elements" do
      get railspress.admin_content_elements_path
      expect(response.body).not_to include("Deleted Element")
    end

    it "filters by content_group_id" do
      get railspress.admin_content_elements_path(content_group_id: footers_group.id)
      expect(response.body).to include(footer_text.name)
      expect(response.body).not_to include(homepage_h1.name)
    end
  end

  describe "GET /railspress/admin/content_elements/:id" do
    it "returns a successful response" do
      get railspress.admin_content_element_path(homepage_h1)
      expect(response).to have_http_status(:ok)
    end

    it "displays the element name and content" do
      get railspress.admin_content_element_path(homepage_h1)
      expect(response.body).to include(homepage_h1.name)
      expect(response.body).to include(homepage_h1.text_content)
    end

    it "displays version history" do
      get railspress.admin_content_element_path(homepage_h1)
      expect(response.body).to include("Version")
    end

    it "redirects for deleted elements" do
      get railspress.admin_content_element_path(deleted_element)
      expect(response).to redirect_to(railspress.admin_content_elements_path)
    end
  end

  describe "GET /railspress/admin/content_elements/new" do
    it "returns a successful response" do
      get railspress.new_admin_content_element_path
      expect(response).to have_http_status(:ok)
    end

    it "pre-selects content group when content_group_id is provided" do
      get railspress.new_admin_content_element_path(content_group_id: headers_group.id)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /railspress/admin/content_elements" do
    context "with valid params" do
      let(:valid_params) do
        {
          content_element: {
            name: "New Hero Text",
            content_group_id: headers_group.id,
            content_type: "text",
            text_content: "Welcome to the new site",
            position: 3
          }
        }
      end

      it "creates a new content element" do
        expect {
          post railspress.admin_content_elements_path, params: valid_params
        }.to change(Railspress::ContentElement, :count).by(1)
      end

      it "redirects to the new element" do
        post railspress.admin_content_elements_path, params: valid_params
        new_element = Railspress::ContentElement.find_by(name: "New Hero Text")
        expect(response).to redirect_to(railspress.admin_content_element_path(new_element))
      end

      it "sets a flash notice" do
        post railspress.admin_content_elements_path, params: valid_params
        expect(flash[:notice]).to include("New Hero Text")
      end

      it "creates a required element when required is true" do
        post railspress.admin_content_elements_path, params: {
          content_element: {
            name: "Required Hero",
            content_group_id: headers_group.id,
            content_type: "text",
            text_content: "Must exist",
            required: true
          }
        }
        element = Railspress::ContentElement.find_by(name: "Required Hero")
        expect(element.required).to be true
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          content_element: {
            name: "",
            content_group_id: headers_group.id,
            content_type: "text",
            text_content: "Content without name"
          }
        }
      end

      it "does not create a content element" do
        expect {
          post railspress.admin_content_elements_path, params: invalid_params
        }.not_to change(Railspress::ContentElement, :count)
      end

      it "returns unprocessable_content status" do
        post railspress.admin_content_elements_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with missing text_content for text type" do
      let(:missing_content_params) do
        {
          content_element: {
            name: "Empty Text",
            content_group_id: headers_group.id,
            content_type: "text",
            text_content: ""
          }
        }
      end

      it "does not create a content element" do
        expect {
          post railspress.admin_content_elements_path, params: missing_content_params
        }.not_to change(Railspress::ContentElement, :count)
      end
    end
  end

  describe "GET /railspress/admin/content_elements/:id/edit" do
    it "returns a successful response" do
      get railspress.edit_admin_content_element_path(homepage_h1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /railspress/admin/content_elements/:id" do
    context "with valid params" do
      it "updates the content element" do
        patch railspress.admin_content_element_path(homepage_h1),
              params: { content_element: { text_content: "Updated Welcome" } }
        expect(homepage_h1.reload.text_content).to eq("Updated Welcome")
      end

      it "redirects to the element" do
        patch railspress.admin_content_element_path(homepage_h1),
              params: { content_element: { text_content: "Updated Welcome" } }
        expect(response).to redirect_to(railspress.admin_content_element_path(homepage_h1))
      end

      it "updates the required flag" do
        patch railspress.admin_content_element_path(homepage_h1),
              params: { content_element: { required: true } }
        expect(homepage_h1.reload.required).to be true
      end

      it "creates a version when text_content changes" do
        expect {
          patch railspress.admin_content_element_path(homepage_h1),
                params: { content_element: { text_content: "Updated Welcome" } }
        }.to change { homepage_h1.content_element_versions.count }.by(1)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content status" do
        patch railspress.admin_content_element_path(homepage_h1),
              params: { content_element: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /railspress/admin/content_elements/:id" do
    it "soft deletes the content element" do
      delete railspress.admin_content_element_path(homepage_h1)
      expect(homepage_h1.reload.deleted?).to be true
    end

    it "does not permanently destroy the record" do
      expect {
        delete railspress.admin_content_element_path(homepage_h1)
      }.not_to change(Railspress::ContentElement, :count)
    end

    it "redirects to the index" do
      delete railspress.admin_content_element_path(homepage_h1)
      expect(response).to redirect_to(railspress.admin_content_elements_path)
    end

    context "when element is required" do
      it "does not delete the element" do
        delete railspress.admin_content_element_path(required_element)
        expect(required_element.reload.deleted?).to be false
      end

      it "redirects with alert" do
        delete railspress.admin_content_element_path(required_element)
        expect(response).to redirect_to(railspress.admin_content_elements_path)
        expect(flash[:alert]).to include("required element")
      end
    end
  end

  describe "GET /railspress/admin/content_elements/:id/inline" do
    it "renders inline form frame with Turbo-Frame header" do
      get railspress.inline_admin_content_element_path(homepage_h1),
          headers: { "Turbo-Frame" => "cms_form_#{homepage_h1.id}_abc123" },
          params: { form_frame_id: "cms_form_#{homepage_h1.id}_abc123", display_frame_id: "cms_display_#{homepage_h1.id}_abc123" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("turbo-frame")
      expect(response.body).to include("text_content")
    end

    it "redirects without Turbo-Frame header" do
      get railspress.inline_admin_content_element_path(homepage_h1)
      expect(response).to redirect_to(railspress.edit_admin_content_element_path(homepage_h1))
    end

    it "redirects for deleted elements" do
      get railspress.inline_admin_content_element_path(deleted_element),
          headers: { "Turbo-Frame" => "cms_form_#{deleted_element.id}_abc123" }
      expect(response).to redirect_to(railspress.admin_content_elements_path)
    end
  end

  describe "GET /railspress/admin/content_elements/:id/image_editor" do
    it "renders image editor for image elements" do
      image_element = Railspress::ContentElement.create!(
        name: "Test Image",
        content_type: :image,
        content_group: headers_group
      )
      # Attach a test image
      image_element.image.attach(
        io: StringIO.new("fake image data"),
        filename: "test.png",
        content_type: "image/png"
      )

      get railspress.image_editor_admin_content_element_path(image_element)
      expect(response).to have_http_status(:ok)
    end

    it "renders compact view when compact=true" do
      image_element = Railspress::ContentElement.create!(
        name: "Test Image Compact",
        content_type: :image,
        content_group: headers_group
      )
      image_element.image.attach(
        io: StringIO.new("fake image data"),
        filename: "test.png",
        content_type: "image/png"
      )

      get railspress.image_editor_admin_content_element_path(image_element, compact: true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Element Image")
    end
  end

  describe "PATCH /railspress/admin/content_elements/:id (content_type change rejected)" do
    it "rejects content_type change" do
      patch railspress.admin_content_element_path(homepage_h1),
            params: { content_element: { content_type: "image" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(homepage_h1.reload.content_type).to eq("text")
    end
  end

  describe "POST /railspress/admin/content_elements (image type)" do
    it "creates an image element with image_hint" do
      post railspress.admin_content_elements_path, params: {
        content_element: {
          name: "Hero Image",
          content_group_id: headers_group.id,
          content_type: "image",
          image_hint: "1920x600, 16:9 landscape"
        }
      }
      element = Railspress::ContentElement.find_by(name: "Hero Image")
      expect(element).to be_present
      expect(element.image?).to be true
      expect(element.image_hint).to eq("1920x600, 16:9 landscape")
    end
  end

  describe "PATCH /railspress/admin/content_elements/:id (inline)" do
    it "returns turbo stream for inline update" do
      patch railspress.admin_content_element_path(homepage_h1),
            params: {
              content_element: { text_content: "Inline Updated" },
              form_frame_id: "cms_form_#{homepage_h1.id}_abc123",
              display_frame_id: "cms_display_#{homepage_h1.id}_abc123"
            },
            headers: { "Turbo-Frame" => "cms_form_#{homepage_h1.id}_abc123" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("cms_form_#{homepage_h1.id}_abc123")
      expect(response.body).to include("cms_display_#{homepage_h1.id}_abc123")
    end

    it "updates the element text content" do
      patch railspress.admin_content_element_path(homepage_h1),
            params: {
              content_element: { text_content: "Inline Updated" },
              form_frame_id: "cms_form_#{homepage_h1.id}_abc123"
            },
            headers: { "Turbo-Frame" => "cms_form_#{homepage_h1.id}_abc123" }
      expect(homepage_h1.reload.text_content).to eq("Inline Updated")
    end

    it "creates a version on inline update" do
      expect {
        patch railspress.admin_content_element_path(homepage_h1),
              params: {
                content_element: { text_content: "Inline Version Test" },
                form_frame_id: "cms_form_#{homepage_h1.id}_abc123"
              },
              headers: { "Turbo-Frame" => "cms_form_#{homepage_h1.id}_abc123" }
      }.to change { homepage_h1.content_element_versions.count }.by(1)
    end

    it "returns turbo stream with errors for invalid inline update" do
      patch railspress.admin_content_element_path(homepage_h1),
            params: {
              content_element: { name: "" },
              form_frame_id: "cms_form_#{homepage_h1.id}_abc123"
            },
            headers: { "Turbo-Frame" => "cms_form_#{homepage_h1.id}_abc123" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
