# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::ApiKey, type: :model do
  fixtures :users

  let(:actor) { users(:api_admin) }

  describe ".issue!" do
    it "creates an api key with owner and created_by metadata" do
      api_key, token = described_class.issue!(name: "Primary Key", actor: actor)

      expect(api_key.owner).to eq(actor)
      expect(api_key.created_by).to eq(actor)
      expect(token).to match(/\Arp_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}\z/)
    end

    it "stores encrypted secret material" do
      api_key, token = described_class.issue!(name: "Encrypted Key", actor: actor)
      secret = token.split("_").last

      expect(api_key.ciphertext_for(:secret_ciphertext)).to be_present
      expect(api_key.ciphertext_for(:secret_ciphertext)).not_to include(secret)
    end
  end

  describe ".authenticate" do
    it "returns the matching active key for a valid token" do
      api_key, token = described_class.issue!(name: "Auth Key", actor: actor)

      result = described_class.authenticate(token)
      expect(result).to eq(api_key)
    end

    it "returns nil for revoked keys" do
      api_key, token = described_class.issue!(name: "Revoked Key", actor: actor)
      api_key.revoke!(actor: actor)

      expect(described_class.authenticate(token)).to be_nil
    end

    it "returns nil for expired keys" do
      _api_key, token = described_class.issue!(
        name: "Expired Key",
        actor: actor,
        expires_at: 1.day.ago
      )

      expect(described_class.authenticate(token)).to be_nil
    end
  end

  describe "#rotate!" do
    it "creates a replacement key and revokes the original key" do
      api_key, _token = described_class.issue!(name: "Rotate Me", actor: actor)

      replacement_key, replacement_token = api_key.rotate!(actor: actor)

      expect(replacement_key).to be_persisted
      expect(replacement_key.rotated_from).to eq(api_key)
      expect(replacement_key.owner).to eq(api_key.owner)
      expect(api_key.reload.revoked_at).to be_present
      expect(api_key.revoke_reason).to eq("rotated")
      expect(replacement_token).to match(/\Arp_#{Rails.env}_[a-f0-9]{12}_[a-f0-9]{64}\z/)
    end
  end

  describe "#revoke!" do
    it "marks key as revoked with actor metadata" do
      api_key, _token = described_class.issue!(name: "Revoke Me", actor: actor)

      api_key.revoke!(actor: actor, reason: "manual")

      expect(api_key.revoked_at).to be_present
      expect(api_key.revoke_reason).to eq("manual")
      expect(api_key.revoked_by).to eq(actor)
    end
  end
end
