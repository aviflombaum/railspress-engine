# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::Categories", type: :request do
  fixtures "railspress/categories", "railspress/posts", :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Categories API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }

  before do
    Railspress.configure(&:enable_api)
  end

  describe "GET /api/v1/categories" do
    it "returns categories with pagination metadata" do
      get railspress.api_v1_categories_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]["total_count"]).to be >= 1
    end
  end

  describe "GET /api/v1/categories/:id" do
    it "returns a single category" do
      category = railspress_categories(:technology)

      get railspress.api_v1_category_path(category), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(category.id)
    end
  end

  describe "POST /api/v1/categories" do
    it "creates a category with valid params" do
      expect {
        post railspress.api_v1_categories_path,
             headers: headers,
             params: { category: { name: "APIs", description: "API resources" } }
      }.to change(Railspress::Category, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "name")).to eq("APIs")
    end

    it "returns validation errors for invalid params" do
      post railspress.api_v1_categories_path,
           headers: headers,
           params: { category: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/categories/:id" do
    it "updates the category" do
      category = railspress_categories(:technology)

      patch railspress.api_v1_category_path(category),
            headers: headers,
            params: { category: { name: "Engineering" } }

      expect(response).to have_http_status(:ok)
      expect(category.reload.name).to eq("Engineering")
    end
  end

  describe "DELETE /api/v1/categories/:id" do
    it "returns validation errors when category has posts" do
      category = railspress_categories(:technology)

      delete railspress.api_v1_category_path(category), headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to include("Cannot delete record because dependent posts exist")
    end

    it "deletes categories with no posts" do
      category = Railspress::Category.create!(name: "Disposable", slug: "disposable")

      expect {
        delete railspress.api_v1_category_path(category), headers: headers
      }.to change(Railspress::Category, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
