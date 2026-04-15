# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Api::V1::AgentKeyExchanges", type: :request do
  fixtures :users

  let(:actor) { users(:api_admin) }

  before do
    Railspress.configure(&:enable_api)
  end

  describe "POST /api/v1/agent_keys/exchange" do
    it "returns unauthorized without a bootstrap token" do
      post railspress.exchange_api_v1_agent_keys_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for an invalid bootstrap token" do
      post railspress.exchange_api_v1_agent_keys_path,
           headers: { "Authorization" => "Bearer invalid" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "exchanges a bootstrap token into an API key" do
      bootstrap_key, bootstrap_token = Railspress::AgentBootstrapKey.issue!(name: "Agent Onboarding", actor: actor)

      post railspress.exchange_api_v1_agent_keys_path,
           headers: { "Authorization" => "Bearer #{bootstrap_token}" }

      expect(response).to have_http_status(:created)
      body = response.parsed_body.fetch("data")
      issued_api_token = body.dig("api_key", "token")
      expect(issued_api_token).to match(/\Arp_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}\z/)
      expect(bootstrap_key.reload.used_at).to be_present
      expect(bootstrap_key.exchanged_api_key_id).to be_present
    end

    it "rejects replay after the bootstrap token has been used" do
      _bootstrap_key, bootstrap_token = Railspress::AgentBootstrapKey.issue!(name: "One Time", actor: actor)

      post railspress.exchange_api_v1_agent_keys_path,
           headers: { "Authorization" => "Bearer #{bootstrap_token}" }
      expect(response).to have_http_status(:created)

      post railspress.exchange_api_v1_agent_keys_path,
           headers: { "Authorization" => "Bearer #{bootstrap_token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
