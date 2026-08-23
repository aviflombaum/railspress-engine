# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::ApiKeys", type: :request do
  fixtures :users

  let(:actor) { users(:api_admin) }

  before do
    actor_id = actor.id
    Railspress.configure do |config|
      config.enable_api
      config.admin_auth_concern = nil
      config.current_admin_proc = -> { User.find_by(id: actor_id) }
    end
  end

  describe "GET /admin/api_keys" do
    it "returns success for authenticated actors" do
      get railspress.admin_api_keys_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bootstrap Quick Start")
      expect(response.body).to include("Agent Instructions")
      expect(response.body).to include("YOUR_BOOTSTRAP_TOKEN")
      expect(response.body).to include("Agent Bootstrap Keys")
      expect(response.body).to include("API Keys")
      expect(response.body).to include("New Agent Key")
      expect(response.body).to include("Recommended: Install RailsPress Agent")
      expect(response.body).to include("https://agent.railspress.org/install.sh")
      expect(response.body).to include("Project Manifest (Token-Free)")
      expect(response.body).to include("onboard --start /path/to/publishing-project --json")
    end

    it "never redisplays an active bootstrap token on the generic index" do
      _older_key, _older_token = Railspress::AgentBootstrapKey.issue!(
        name: "Older Active Key",
        actor: actor,
        expires_at: 2.hours.from_now
      )
      _newer_key, newer_token = Railspress::AgentBootstrapKey.issue!(
        name: "Newest Active Key",
        actor: actor,
        expires_at: 2.hours.from_now
      )

      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(newer_token)
      expect(response.body).to include("YOUR_BOOTSTRAP_TOKEN")
    end

    it "uses Rails route default_url_options for instruction URLs when present" do
      original_defaults = Rails.application.routes.default_url_options.deep_dup
      Rails.application.routes.default_url_options.clear
      Rails.application.routes.default_url_options.merge!(
        host: "api.example.test",
        protocol: "https",
        port: 8443
      )

      host! "request-host.test"
      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://api.example.test:8443")
      expect(response.body).to include("api_base: https://api.example.test:8443#{railspress.api_v1_posts_path.delete_suffix("/posts")}")
      expect(response.body).to include("$HOME/.railspress/tokens/api.example.test-8443")
      expect(response.body).not_to include("http://request-host.test")
    ensure
      Rails.application.routes.default_url_options.clear
      Rails.application.routes.default_url_options.merge!(original_defaults)
    end

    it "prefers configured public_base_url over route defaults and request host" do
      original_defaults = Rails.application.routes.default_url_options.deep_dup
      Rails.application.routes.default_url_options.clear
      Rails.application.routes.default_url_options.merge!(
        host: "api.example.test",
        protocol: "https",
        port: 8443
      )

      Railspress.configuration.public_base_url = "http://public.example.org/publishing"
      host! "request-host.test"

      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("http://public.example.org/publishing")
      expect(response.body).to include("host: http://public.example.org/publishing")
      expect(response.body).to include("api_base: http://public.example.org/publishing#{railspress.api_v1_posts_path.delete_suffix("/posts")}")
      expect(response.body).to include("$HOME/.railspress/tokens/public.example.org-publishing")
      expect(response.body).not_to include("https://api.example.test:8443")
      expect(response.body).not_to include("http://request-host.test")
    ensure
      Rails.application.routes.default_url_options.clear
      Rails.application.routes.default_url_options.merge!(original_defaults)
    end

    it "includes a request host non-default port in the token filename" do
      host! "127.0.0.1:3129"

      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$HOME/.railspress/tokens/127.0.0.1-3129")
    end

    it "omits default HTTPS ports from the token filename" do
      Railspress.configuration.public_base_url = "https://blog.example.com:443"

      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$HOME/.railspress/tokens/blog.example.com")
      expect(response.body).not_to include("$HOME/.railspress/tokens/blog.example.com-443")
    end

    it "keeps separate subdomains in separate token files" do
      Railspress.configuration.public_base_url = "https://blog.example.com"
      get railspress.admin_api_keys_path
      blog_instructions = response.body

      Railspress.configuration.public_base_url = "https://docs.example.com"
      get railspress.admin_api_keys_path

      expect(blog_instructions).to include("$HOME/.railspress/tokens/blog.example.com")
      expect(response.body).to include("$HOME/.railspress/tokens/docs.example.com")
    end

    it "uses a safe fallback token filename when the configured URL has no host" do
      Railspress.configuration.public_base_url = "/publishing"

      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$HOME/.railspress/tokens/railspress-app")
    end
  end

  describe "POST /admin/api_keys" do
    it "creates a key and renders one-time token reveal" do
      expect {
        post railspress.admin_api_keys_path, params: { api_key: { name: "CI Integration" } }
      }.to change(Railspress::ApiKey, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.body).to include("Copy this key now")
      expect(response.body).to include("API Quick Start")
      expect(response.body).to include("API Key Instructions")
      expect(response.body).to include("export RAILSPRESS_TOKEN=")
      expect(response.body).to include("token store")
      expect(response.body).to include("prime --start /path/to/publishing-project --json")
      expect(response.body).not_to include("install -d -m 700")
      expect(response.body).not_to include("--replace")
      expect(response.body).to include("$HOME/.railspress/tokens/www.example.com")
      expect(response.body).not_to include("~/.railspress_token")
      expect(response.body).to match(/rp_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}/)
    end

    it "defaults new keys to no expiration when no expires_at is provided" do
      post railspress.admin_api_keys_path, params: { api_key: { name: "Default Expiration Key" } }

      created_key = Railspress::ApiKey.order(:id).last
      expect(created_key.expires_at).to be_nil
    end
  end

  describe "POST /admin/api_keys/:id/rotate" do
    it "rotates key and revokes the previous one" do
      api_key, _token = Railspress::ApiKey.issue!(name: "Rotate Target", actor: actor)

      expect {
        post railspress.rotate_admin_api_key_path(api_key)
      }.to change(Railspress::ApiKey, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.body).to include("API Quick Start")
      expect(api_key.reload.revoked_at).to be_present
      expect(api_key.revoke_reason).to eq("rotated")
    end

    it "keeps no expiration when rotating a key with no expiration" do
      api_key, _token = Railspress::ApiKey.issue!(name: "Rotate No Expiry", actor: actor, expires_at: nil)

      post railspress.rotate_admin_api_key_path(api_key)

      replacement_key = Railspress::ApiKey.where.not(id: api_key.id).order(:id).last
      expect(replacement_key.expires_at).to be_nil
    end
  end

  describe "POST /admin/api_keys/:id/revoke" do
    it "revokes the requested key" do
      api_key, _token = Railspress::ApiKey.issue!(name: "Revoke Target", actor: actor)

      post railspress.revoke_admin_api_key_path(api_key)

      expect(response).to redirect_to(railspress.admin_api_keys_path)
      expect(api_key.reload.revoked_at).to be_present
      expect(api_key.revoke_reason).to eq("revoked")
    end
  end

  describe "authentication guard" do
    it "calls the configured host authentication method" do
      Railspress.configure do |config|
        config.enable_api
        config.admin_authentication_method = :spec_authenticate_admin!
      end

      get railspress.admin_api_keys_path

      expect(response).to have_http_status(:forbidden)
    end

    it "uses the configured host current admin method" do
      Railspress.configure do |config|
        config.enable_api
        config.admin_authentication_method = :spec_authenticate_admin!
        config.current_admin_method = :spec_current_admin
        config.current_admin_proc = nil
      end

      get railspress.admin_api_keys_path, headers: {
        "X-Railspress-Admin" => "allowed",
        "X-Railspress-Actor-ID" => actor.id.to_s
      }

      expect(response).to have_http_status(:ok)
    end

    it "raises a configuration error when the authentication method is unavailable" do
      Railspress.configure do |config|
        config.enable_api
        config.admin_authentication_method = :missing_admin_authentication!
      end

      expect {
        get railspress.admin_api_keys_path
      }.to raise_error(Railspress::ConfigurationError, /missing_admin_authentication!.*ApplicationController/)
    end

    it "redirects when no current api actor is available" do
      Railspress.configure do |config|
        config.enable_api
        config.current_admin_proc = -> { nil }
      end

      get railspress.admin_api_keys_path

      expect(response).to redirect_to(railspress.admin_root_path)
    end

    it "allows request-scoped current_admin_proc strategies" do
      actor_id = actor.id
      Railspress.configure do |config|
        config.enable_api
        config.admin_auth_concern = nil
        config.current_admin_proc = lambda {
          header_id = request.headers["X-Railspress-Actor-ID"]
          User.find_by(id: header_id)
        }
      end

      get railspress.admin_api_keys_path, headers: { "X-Railspress-Actor-ID" => actor_id.to_s }

      expect(response).to have_http_status(:ok)
    end

    it "supports current_user method auth via configured admin_auth_concern" do
      actor_id = actor.id
      Railspress.configure do |config|
        config.enable_api
        config.admin_auth_concern = "Railspress::SpecAdminAuthConcern"
        config.current_admin_proc = nil
        config.current_admin_method = :current_user
      end

      Rails.application.reloader.prepare!
      get railspress.admin_api_keys_path, headers: { "X-Railspress-Actor-ID" => actor_id.to_s }

      expect(response).to have_http_status(:ok)
    end
  end
end
