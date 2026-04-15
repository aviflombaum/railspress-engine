# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::AgentBootstrapKey, type: :model do
  fixtures :users

  let(:actor) { users(:api_admin) }

  describe ".issue!" do
    it "creates a bootstrap key with owner and created_by metadata" do
      bootstrap_key, token = described_class.issue!(name: "Bootstrap Key", actor: actor)

      expect(bootstrap_key.owner).to eq(actor)
      expect(bootstrap_key.created_by).to eq(actor)
      expect(token).to match(/\Arpb_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}\z/)
      expect(bootstrap_key.expires_at).to be_between(59.minutes.from_now, 61.minutes.from_now)
    end

    it "stores encrypted secret material" do
      bootstrap_key, token = described_class.issue!(name: "Encrypted Bootstrap", actor: actor)
      secret = token.split("_").last

      expect(bootstrap_key.ciphertext_for(:secret_ciphertext)).to be_present
      expect(bootstrap_key.ciphertext_for(:secret_ciphertext)).not_to include(secret)
    end
  end

  describe ".authenticate" do
    it "returns matching active key for a valid token" do
      bootstrap_key, token = described_class.issue!(name: "Auth Bootstrap", actor: actor)

      expect(described_class.authenticate(token)).to eq(bootstrap_key)
    end

    it "returns nil for used bootstrap keys" do
      bootstrap_key, token = described_class.issue!(name: "Used Bootstrap", actor: actor)
      bootstrap_key.exchange!

      expect(described_class.authenticate(token)).to be_nil
    end

    it "returns nil for revoked bootstrap keys" do
      bootstrap_key, token = described_class.issue!(name: "Revoked Bootstrap", actor: actor)
      bootstrap_key.revoke!(actor: actor)

      expect(described_class.authenticate(token)).to be_nil
    end

    it "returns nil for expired bootstrap keys" do
      _bootstrap_key, token = described_class.issue!(
        name: "Expired Bootstrap",
        actor: actor,
        expires_at: 1.minute.ago
      )

      expect(described_class.authenticate(token)).to be_nil
    end
  end

  describe "#exchange!" do
    it "issues an API key and marks the bootstrap key as used" do
      bootstrap_key, _token = described_class.issue!(name: "Exchange Me", actor: actor)

      issued_api_key, issued_token = bootstrap_key.exchange!(ip_address: "127.0.0.1")

      expect(issued_api_key).to be_persisted
      expect(issued_token).to match(/\Arp_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}\z/)
      expect(bootstrap_key.reload.used_at).to be_present
      expect(bootstrap_key.used_ip).to eq("127.0.0.1")
      expect(bootstrap_key.exchanged_api_key).to eq(issued_api_key)
      expect(bootstrap_key.status).to eq("used")
    end

    it "raises when the bootstrap key is no longer active" do
      bootstrap_key, _token = described_class.issue!(name: "Expired Exchange", actor: actor, expires_at: 1.minute.ago)

      expect { bootstrap_key.exchange! }.to raise_error(Railspress::AgentBootstrapKey::ExchangeError)
    end
  end
end
