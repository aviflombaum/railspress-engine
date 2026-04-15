# frozen_string_literal: true

# Configure Active Record Encryption keys for dummy app/test environment.
# Host applications should configure their own keys in credentials or env vars.
Rails.application.config.active_record.encryption.primary_key = ENV.fetch(
  "RAILSPRESS_ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY",
  "a9f4d0e3c2b1486fa4d2b9f1e8c7a6b5"
)
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch(
  "RAILSPRESS_ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY",
  "c4a7e9f1d2b36a58f9e0d1c2b3a4e5f6"
)
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch(
  "RAILSPRESS_ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT",
  "railspress-dummy-active-record-encryption-salt"
)
