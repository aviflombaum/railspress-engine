# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "stringio"
require "tmpdir"

RSpec.describe Railspress::Diagnostics do
  TestMigration = Data.define(:version, :name, :filename)

  let(:migration_context) do
    instance_double(
      ActiveRecord::MigrationContext,
      pending_migration_versions: [],
      migrations: []
    )
  end

  before do
    Railspress.reset_configuration!
    Railspress.configuration.admin_authentication_method = :spec_authenticate_admin!
  end

  after do
    Railspress.reset_configuration!
  end

  it "reports a healthy explicit auth and migration configuration" do
    with_migration_roots(copied: true) do |engine_root, app_root|
      report = described_class.new(
        application: Rails.application,
        engine_root:,
        app_root:,
        migration_context:
      ).call

      expect(report).not_to be_failures
      expect(report.findings).to include(
        have_attributes(code: :admin_authentication, severity: :pass),
        have_attributes(code: :migrations_copied, severity: :pass)
      )
    end
  end

  it "fails when a configured admin authentication method is unavailable" do
    Railspress.configuration.admin_authentication_method = :missing_admin_authentication!

    report = described_class.new(migration_context:).call(include_migrations: false)

    expect(report.exit_status).to eq(1)
    expect(report.findings).to include(
      have_attributes(code: :admin_authentication_method_missing, severity: :failure)
    )
  end

  it "warns when admin authentication is implicit" do
    Railspress.configuration.admin_authentication_method = nil

    report = described_class.new(migration_context:).call(include_migrations: false)

    expect(report).not_to be_failures
    expect(report.findings).to include(
      have_attributes(code: :admin_authentication_implicit, severity: :warning)
    )
  end

  it "reports missing API encryption and current-admin configuration" do
    encryption_options = ActiveSupport::OrderedOptions.new
    active_record_options = ActiveSupport::OrderedOptions.new
    application_config = ActiveSupport::OrderedOptions.new
    active_record_options.encryption = encryption_options
    application_config.active_record = active_record_options
    application = instance_double(
      Rails::Application,
      config: application_config,
      credentials: {},
      routes: Rails.application.routes
    )
    Railspress.configuration.enable_api
    Railspress.configuration.current_admin_method = :missing_current_admin

    report = described_class.new(application:, migration_context:).call(include_migrations: false)

    expect(report.findings).to include(
      have_attributes(code: :current_admin_method_missing, severity: :failure),
      have_attributes(code: :api_encryption_missing, severity: :failure)
    )
  end

  it "distinguishes uncopied from copied but pending RailsPress migrations" do
    with_migration_roots(copied: true) do |engine_root, app_root, copied_path|
      migration = TestMigration.new(20_260_821_000_001, "CreateRailspressExample", copied_path.to_s)
      context = instance_double(
        ActiveRecord::MigrationContext,
        pending_migration_versions: [ migration.version ],
        migrations: [ migration ]
      )

      report = described_class.new(
        engine_root:,
        app_root:,
        migration_context: context
      ).call

      expect(report.findings).to include(
        have_attributes(code: :migrations_copied, severity: :pass),
        have_attributes(code: :migrations_pending, severity: :failure)
      )
    end

    with_migration_roots(copied: false) do |engine_root, app_root|
      report = described_class.new(
        engine_root:,
        app_root:,
        migration_context:
      ).call

      expect(report.findings).to include(
        have_attributes(code: :migrations_uncopied, severity: :failure)
      )
    end
  end

  it "renders stable status labels and an accurate summary" do
    report = described_class::Report.new([
      described_class::Finding.new(code: :one, severity: :pass, label: "One", message: "ok", remediation: nil),
      described_class::Finding.new(code: :two, severity: :warning, label: "Two", message: "check", remediation: "Review it."),
      described_class::Finding.new(code: :three, severity: :failure, label: "Three", message: "bad", remediation: nil)
    ])
    output = StringIO.new

    report.render(io: output)

    expect(output.string).to include("[PASS] One: ok")
    expect(output.string).to include("[WARN] Two: check")
    expect(output.string).to include("[FAIL] Three: bad")
    expect(output.string).to include("Suggestion: Review it.")
    expect(output.string).to include("Suggestion: Correct this failure and rerun bin/rails railspress:doctor.")
    expect(output.string).to include("1 failure, 1 warning, 1 pass")
    expect(output.string).to include("Doctor found failures that require action.")
    expect(output.string).not_to include("\e[")
  end

  it "color codes statuses and the summary when color is enabled" do
    report = described_class::Report.new([
      described_class::Finding.new(code: :one, severity: :pass, label: "One", message: "ok", remediation: nil),
      described_class::Finding.new(code: :two, severity: :warning, label: "Two", message: "check", remediation: nil),
      described_class::Finding.new(code: :three, severity: :failure, label: "Three", message: "bad", remediation: nil)
    ])
    output = StringIO.new

    report.render(io: output, color: true)

    expect(output.string).to include("\e[32m[PASS]\e[0m")
    expect(output.string).to include("\e[33m[WARN]\e[0m")
    expect(output.string).to include("\e[31m[FAIL]\e[0m")
    expect(output.string).to include("\e[31m1 failure, 1 warning, 1 pass\e[0m")
  end

  it "requires every shipped migration even when its feature is disabled" do
    expect(Railspress).not_to be_api_enabled

    with_migration_roots(copied: false) do |engine_root, app_root|
      report = described_class.new(
        engine_root:,
        app_root:,
        migration_context:
      ).call

      finding = report.findings.find { |item| item.code == :migrations_uncopied }
      expect(finding.message).to include("all shipped migrations are required, even for disabled features")
      expect(finding.remediation).to include("railspress:install:migrations", "db:migrate", "rerun doctor")
    end
  end

  it "logs and reports database inspection failures" do
    context = instance_double(ActiveRecord::MigrationContext)
    allow(context).to receive(:pending_migration_versions).and_raise(
      ActiveRecord::ConnectionNotEstablished,
      "database unavailable"
    )
    allow(Rails.logger).to receive(:error)

    with_migration_roots(copied: true) do |engine_root, app_root|
      report = described_class.new(
        engine_root:,
        app_root:,
        migration_context: context
      ).call

      expect(report.findings).to include(
        have_attributes(code: :migration_inspection_failed, severity: :failure)
      )
    end
    expect(Rails.logger).to have_received(:error).with(/database unavailable/)
  end

  it "reports deprecated initializer settings once" do
    allow(Railspress.deprecator).to receive(:warn)
    Railspress.configuration.current_api_actor_method
    Railspress.configuration.current_api_actor_method

    report = described_class.new(migration_context:).call(include_migrations: false)

    finding = report.findings.find { |item| item.code == :deprecated_settings }
    expect(finding.message.scan("config.current_api_actor_method").length).to eq(1)
  end

  def with_migration_roots(copied:)
    Dir.mktmpdir do |directory|
      root = Pathname(directory)
      engine_root = root.join("engine")
      app_root = root.join("app")
      engine_path = engine_root.join("db/migrate/20260821000001_create_railspress_example.rb")
      copied_path = app_root.join("db/migrate/20260821000002_create_railspress_example.railspress.rb")
      FileUtils.mkdir_p(engine_path.dirname)
      FileUtils.mkdir_p(copied_path.dirname)
      FileUtils.touch(engine_path)
      FileUtils.touch(copied_path) if copied

      yield engine_root, app_root, copied_path
    end
  end
end
