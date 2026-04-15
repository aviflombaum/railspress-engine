# frozen_string_literal: true

require "openssl"

module Railspress
  class AgentBootstrapKey < ApplicationRecord
    self.table_name = "railspress_agent_bootstrap_keys"

    DEFAULT_TTL = 1.hour

    class ExchangeError < StandardError; end

    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :created_by, polymorphic: true, optional: true
    belongs_to :revoked_by, polymorphic: true, optional: true
    belongs_to :exchanged_api_key, class_name: "Railspress::ApiKey", optional: true

    encrypts :secret_ciphertext

    normalizes :name, with: ->(value) { value.to_s.strip }
    normalizes :token_prefix, with: ->(value) { value.to_s.downcase }

    validates :name, presence: true, length: { maximum: 120 }
    validates :token_prefix, presence: true, length: { is: 12 }
    validates :token_digest, presence: true, uniqueness: true, length: { is: 64 }
    validates :secret_ciphertext, presence: true
    validates :expires_at, presence: true
    validates :global_uuid, presence: true, uniqueness: true

    scope :recent, -> { order(created_at: :desc) }
    scope :revoked, -> { where.not(revoked_at: nil) }
    scope :used, -> { where.not(used_at: nil) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }
    scope :active, -> {
      where(revoked_at: nil, used_at: nil)
        .where("expires_at > ?", Time.current)
    }

    before_validation :set_global_uuid, on: :create

    class << self
      def issue!(name:, actor:, owner: actor, expires_at: DEFAULT_TTL.from_now)
        prefix = generate_prefix
        raw_secret = generate_secret
        token = build_token(prefix, raw_secret)

        bootstrap_key = create!(
          name: name,
          token_prefix: prefix,
          token_digest: digest(raw_secret),
          secret_ciphertext: raw_secret,
          owner: owner,
          created_by: actor,
          expires_at: expires_at
        )

        [ bootstrap_key, token ]
      end

      def authenticate(raw_token)
        parsed = parse_token(raw_token)
        return nil unless parsed

        candidate = active.where(token_prefix: parsed[:prefix]).recent.first
        return nil unless candidate
        return nil unless secure_digest_match?(candidate.token_digest, digest(parsed[:secret]))

        candidate
      end

      def build_token(prefix, raw_secret)
        "rpb_#{Rails.env}_#{prefix}_#{raw_secret}"
      end

      def digest(raw_secret)
        OpenSSL::HMAC.hexdigest("SHA256", digest_key, raw_secret.to_s)
      end

      def parse_token(raw_token)
        return nil if raw_token.blank?

        match = raw_token.match(/\Arpb_[a-z0-9_]+_([a-f0-9]{12})_([a-f0-9]{64})\z/)
        return nil unless match

        { prefix: match[1], secret: match[2] }
      end

      private

      def digest_key
        Rails.application.secret_key_base.to_s
      end

      def generate_prefix
        SecureRandom.hex(6)
      end

      def generate_secret
        SecureRandom.hex(32)
      end

      def secure_digest_match?(stored_digest, candidate_digest)
        return false if stored_digest.blank? || candidate_digest.blank?
        return false unless stored_digest.bytesize == candidate_digest.bytesize

        ActiveSupport::SecurityUtils.secure_compare(stored_digest, candidate_digest)
      end
    end

    def exchange!(ip_address: nil, api_key_name: default_api_key_name, api_key_expires_at: nil)
      raise ExchangeError, "Bootstrap key is not active." unless active?

      transaction do
        api_key_actor = owner || created_by
        api_key_owner = owner || api_key_actor
        api_key, plain_token = Railspress::ApiKey.issue!(
          name: api_key_name,
          actor: api_key_actor,
          owner: api_key_owner,
          expires_at: api_key_expires_at
        )

        update!(
          used_at: Time.current,
          used_ip: ip_address,
          exchanged_api_key: api_key
        )

        [ api_key, plain_token ]
      end
    end

    def revoke!(actor:, reason: "revoked")
      update!(
        revoked_at: Time.current,
        revoke_reason: reason,
        revoked_by: actor
      )
    end

    def active?
      revoked_at.nil? && used_at.nil? && expires_at > Time.current
    end

    def status
      return "revoked" if revoked_at.present?
      return "used" if used_at.present?
      return "expired" if expires_at <= Time.current

      "active"
    end

    private

    def default_api_key_name
      "#{name} (API Key)"
    end

    def set_global_uuid
      self.global_uuid ||= SecureRandom.uuid
    end
  end
end
