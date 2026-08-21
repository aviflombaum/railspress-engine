# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::Prime", type: :request do
  fixtures :users

  let(:actor) { users(:api_admin) }
  let(:api_token) { Railspress::ApiKey.issue!(name: "Prime API", actor: actor).last }
  let(:headers) { { "Authorization" => "Bearer #{api_token}" } }

  before do
    Railspress.configure do |config|
      config.enable_api
      config.enable_post_images
      config.enable_focal_points
    end
  end

  describe "GET /api/v1/prime" do
    it "returns unauthorized without a bearer token" do
      get railspress.api_v1_prime_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns API capabilities and defaults" do
      get railspress.api_v1_prime_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body.fetch("data")

      expect(body.fetch("service")).to eq("Railspress API")
      expect(body.fetch("version")).to eq("v1")
      expect(body.dig("authentication", "token_types")).to include("api_key", "agent_bootstrap_key")
      expect(body.dig("authentication", "agent_bootstrap_exchange_endpoint")).to eq(railspress.exchange_api_v1_agent_keys_path)
      expect(body.dig("defaults", "post_status")).to eq("draft")
      expect(body.dig("defaults", "publish_with_explicit_status")).to eq(true)
      expect(body.dig("capabilities", "posts", "publish_supported")).to eq(true)
      expect(body.dig("capabilities", "posts", "content_formats")).to eq(%w[html markdown plain auto])
      expect(body.dig("capabilities", "posts", "read_content_format")).to eq("html")
      expect(body.dig("capabilities", "post_media", "inline_images")).to eq(true)
      expect(body.dig("capabilities", "post_media", "gallery_images")).to eq(true)
      expect(body.dig("endpoints", "prime")).to eq(railspress.api_v1_prime_path)
      expect(body.dig("endpoints", "posts")).to eq(railspress.api_v1_posts_path)
      expect(body.dig("endpoints", "post_assets")).to eq(railspress.api_v1_post_assets_path)
      expect(body.dig("endpoints", "post_gallery_images")).to eq(
        "#{railspress.api_v1_posts_path}/:post_id/gallery_images"
      )
      expect(body.dig("key", "name")).to eq("Prime API")
    end

    it "does not run the host admin authentication method" do
      Railspress.configuration.admin_authentication_method = :spec_authenticate_admin!

      get railspress.api_v1_prime_path, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end
end
