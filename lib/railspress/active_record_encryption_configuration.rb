# frozen_string_literal: true

module Railspress
  class ActiveRecordEncryptionConfiguration
    REQUIRED_KEYS = %i[primary_key deterministic_key key_derivation_salt].freeze
    SETUP_COMMAND = "bin/rails db:encryption:init"

    def initialize(application)
      @application = application
    end

    def configured?
      missing_keys.empty?
    end

    def missing_keys
      REQUIRED_KEYS.reject { |key| effective_value(key).present? }
    end

    def validate!
      return unless Railspress.api_enabled?
      return if configured?

      raise Railspress::ConfigurationError,
        "RailsPress Agents & API requires Active Record Encryption credentials. " \
        "Missing: #{missing_keys.join(", ")}. " \
        "Run `#{SETUP_COMMAND}`, then store the generated values in your host " \
        "application's credentials or secret-management system."
    end

    private

    attr_reader :application

    def effective_value(key)
      options = application.config.active_record.encryption
      return options[key] if options.key?(key)

      application.credentials.dig(:active_record_encryption, key)
    end
  end
end
