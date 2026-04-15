# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::AgentBootstrapKeys", type: :request do
  fixtures :users

  let(:actor) { users(:api_admin) }

  before do
    actor_id = actor.id
    Railspress.configure do |config|
      config.enable_api
      config.current_api_actor_proc = -> { User.find_by(id: actor_id) }
    end
  end

  describe "GET /admin/agent_bootstrap_keys/new" do
    it "returns success for authenticated actors" do
      get railspress.new_admin_agent_bootstrap_key_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Agent Key")
    end
  end

  describe "POST /admin/agent_bootstrap_keys" do
    it "creates a bootstrap key and renders one-time reveal" do
      expect {
        post railspress.admin_agent_bootstrap_keys_path,
             params: { agent_bootstrap_key: { name: "Cora Setup" } }
      }.to change(Railspress::AgentBootstrapKey, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.body).to include("Bootstrap Token")
      expect(response.body).to include("Bootstrap Quick Start")
      expect(response.body).to include(railspress.exchange_api_v1_agent_keys_path)
      expect(response.body).to match(/rpb_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}/)
    end

    it "defaults bootstrap keys to one-hour expiration" do
      post railspress.admin_agent_bootstrap_keys_path,
           params: { agent_bootstrap_key: { name: "One Hour Default" } }

      created_key = Railspress::AgentBootstrapKey.order(:id).last
      expect(created_key.expires_at).to be_between(59.minutes.from_now, 61.minutes.from_now)
    end

    it "uses configured public_base_url in bootstrap instructions" do
      Railspress.configuration.public_base_url = "https://public.example.org"
      host! "request-host.test"

      post railspress.admin_agent_bootstrap_keys_path,
           params: { agent_bootstrap_key: { name: "Public URL Key" } }

      expect(response).to have_http_status(:created)
      expect(response.body).to include("https://public.example.org")
      expect(response.body).not_to include("http://request-host.test")
    end
  end

  describe "POST /admin/agent_bootstrap_keys/:id/revoke" do
    it "revokes the requested bootstrap key" do
      bootstrap_key, _token = Railspress::AgentBootstrapKey.issue!(name: "Revoke Bootstrap", actor: actor)

      post railspress.revoke_admin_agent_bootstrap_key_path(bootstrap_key)

      expect(response).to redirect_to(railspress.admin_api_keys_path)
      expect(bootstrap_key.reload.revoked_at).to be_present
      expect(bootstrap_key.revoke_reason).to eq("revoked")
    end
  end
end
