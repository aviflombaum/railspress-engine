# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::Tags", type: :request do
  fixtures "railspress/tags", "railspress/posts", "railspress/taggings", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Tags API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }

  before do
    Railspress.configure(&:enable_api)
  end

  describe "GET /api/v1/tags" do
    it "returns tags with pagination metadata" do
      get railspress.api_v1_tags_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]["total_count"]).to be >= 1
    end
  end

  describe "GET /api/v1/tags/:id" do
    it "returns a single tag" do
      tag = railspress_tags(:ruby)

      get railspress.api_v1_tag_path(tag), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(tag.id)
    end
  end

  describe "POST /api/v1/tags" do
    it "creates a tag with valid params" do
      expect {
        post railspress.api_v1_tags_path,
             headers: headers,
             params: { tag: { name: "security" } }
      }.to change(Railspress::Tag, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "name")).to eq("security")
    end

    it "returns validation errors for invalid params" do
      post railspress.api_v1_tags_path,
           headers: headers,
           params: { tag: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/tags/:id" do
    it "updates the tag" do
      tag = railspress_tags(:ruby)

      patch railspress.api_v1_tag_path(tag),
            headers: headers,
            params: { tag: { name: "ruby-on-rails" } }

      expect(response).to have_http_status(:ok)
      expect(tag.reload.name).to eq("ruby-on-rails")
    end
  end

  describe "DELETE /api/v1/tags/:id" do
    it "deletes the tag" do
      tag = Railspress::Tag.create!(name: "temporary-delete", slug: "temporary-delete")

      expect {
        delete railspress.api_v1_tag_path(tag), headers: headers
      }.to change(Railspress::Tag, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
