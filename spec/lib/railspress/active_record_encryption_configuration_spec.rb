# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::ActiveRecordEncryptionConfiguration do
  let(:encryption_options) { ActiveSupport::OrderedOptions.new }
  let(:active_record_options) { ActiveSupport::OrderedOptions.new }
  let(:application_config) { ActiveSupport::OrderedOptions.new }
  let(:credentials) { { active_record_encryption: credential_values } }
  let(:application) { instance_double(Rails::Application, config: application_config, credentials: credentials) }
  let(:credential_values) { {} }

  before do
    Railspress.reset_configuration!
    active_record_options.encryption = encryption_options
    application_config.active_record = active_record_options
  end

  after do
    Railspress.reset_configuration!
  end

  it "accepts credentials managed by the host application" do
    credential_values.merge!(
      primary_key: "primary",
      deterministic_key: "deterministic",
      key_derivation_salt: "salt"
    )

    expect(described_class.new(application)).to be_configured
  end

  it "accepts explicit Active Record Encryption configuration" do
    encryption_options.primary_key = "primary"
    encryption_options.deterministic_key = "deterministic"
    encryption_options.key_derivation_salt = "salt"

    expect(described_class.new(application)).to be_configured
  end

  it "does not raise when the API is disabled" do
    expect {
      described_class.new(application).validate!
    }.not_to raise_error
  end

  it "raises a RailsPress configuration error with the setup command when the API is enabled" do
    Railspress.configuration.enable_api

    expect {
      described_class.new(application).validate!
    }.to raise_error(
      Railspress::ConfigurationError,
      /Missing: primary_key, deterministic_key, key_derivation_salt.*bin\/rails db:encryption:init/
    )
  end

  it "reports only missing effective values" do
    credential_values.merge!(
      primary_key: "primary",
      deterministic_key: "deterministic",
      key_derivation_salt: "salt"
    )
    encryption_options.deterministic_key = nil

    expect(described_class.new(application).missing_keys).to eq([ :deterministic_key ])
  end
end
