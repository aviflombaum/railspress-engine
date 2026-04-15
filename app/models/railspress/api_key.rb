# frozen_string_literal: true

require "openssl"

module Railspress
  class ApiKey < ApplicationRecord
    self.table_name = "railspress_api_keys"

    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :created_by, polymorphic: true, optional: true
    belongs_to :rotated_by, polymorphic: true, optional: true
    belongs_to :revoked_by, polymorphic: true, optional: true
    belongs_to :rotated_from, class_name: "Railspress::ApiKey", optional: true

    encrypts :secret_ciphertext

    normalizes :name, with: ->(value) { value.to_s.strip }
    normalizes :token_prefix, with: ->(value) { value.to_s.downcase }

    validates :name, presence: true, length: { maximum: 120 }
    validates :token_prefix, presence: true, length: { is: 12 }
    validates :token_digest, presence: true, uniqueness: true, length: { is: 64 }
    validates :secret_ciphertext, presence: true
    validates :global_uuid, presence: true, uniqueness: true

    scope :recent, -> { order(created_at: :desc) }
    scope :revoked, -> { where.not(revoked_at: nil) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }
    scope :active, -> {
      where(revoked_at: nil)
        .where("expires_at IS NULL OR expires_at > ?", Time.current)
    }

    before_validation :set_global_uuid, on: :create

    class << self
      def issue!(name:, actor:, owner: actor, expires_at: nil, rotated_from: nil)
        prefix = generate_prefix
        raw_secret = generate_secret
        token = build_token(prefix, raw_secret)

        api_key = create!(
          name: name,
          token_prefix: prefix,
          token_digest: digest(raw_secret),
          secret_ciphertext: raw_secret,
          owner: owner,
          created_by: actor,
          expires_at: expires_at,
          rotated_from: rotated_from
        )

        [ api_key, token ]
      end

      def authenticate(raw_token, ip_address: nil)
        parsed = parse_token(raw_token)
        return nil unless parsed

        candidate = active.where(token_prefix: parsed[:prefix]).recent.first
        return nil unless candidate
        return nil unless secure_digest_match?(candidate.token_digest, digest(parsed[:secret]))

        candidate.touch_usage!(ip_address: ip_address)
        candidate
      end

      def build_token(prefix, raw_secret)
        "rp_#{Rails.env}_#{prefix}_#{raw_secret}"
      end

      def digest(raw_secret)
        OpenSSL::HMAC.hexdigest("SHA256", digest_key, raw_secret.to_s)
      end

      def parse_token(raw_token)
        return nil if raw_token.blank?

        match = raw_token.match(/\Arp_[a-z0-9_]+_([a-f0-9]{12})_([a-f0-9]{64})\z/)
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

    def revoke!(actor:, reason: "revoked")
      update!(
        revoked_at: Time.current,
        revoke_reason: reason,
        revoked_by: actor
      )
    end

    def rotate!(actor:, name: self.name, expires_at: self.expires_at)
      transaction do
        replacement_key, plain_token = self.class.issue!(
          name: name,
          actor: actor,
          owner: owner,
          expires_at: expires_at,
          rotated_from: self
        )

        update!(
          revoked_at: Time.current,
          revoke_reason: "rotated",
          revoked_by: actor,
          rotated_by: actor
        )

        [ replacement_key, plain_token ]
      end
    end

    def active?
      revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
    end

    def status
      return "revoked" if revoked_at.present?
      return "expired" if expires_at.present? && expires_at <= Time.current

      "active"
    end

    def touch_usage!(ip_address: nil)
      update_columns(last_used_at: Time.current, last_used_ip: ip_address, updated_at: Time.current)
    end

    private

    def set_global_uuid
      self.global_uuid ||= SecureRandom.uuid
    end
  end
end
