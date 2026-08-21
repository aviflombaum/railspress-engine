# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe Railspress::Upgrade do
  let(:diagnostics_class) { class_double(Railspress::Diagnostics) }
  let(:diagnostics) { instance_double(Railspress::Diagnostics) }
  let(:task_runner) { instance_double(described_class::RakeTaskRunner) }
  let(:output) { StringIO.new }
  let(:pass_report) do
    Railspress::Diagnostics::Report.new([
      Railspress::Diagnostics::Finding.new(
        code: :configuration,
        severity: :pass,
        label: "Configuration",
        message: "ok",
        remediation: nil
      )
    ])
  end

  before do
    allow(diagnostics_class).to receive(:new).and_return(diagnostics)
    allow(diagnostics).to receive(:call).with(include_migrations: false).and_return(pass_report)
    allow(diagnostics).to receive(:call).with(no_args).and_return(pass_report)
    allow(diagnostics).to receive(:uncopied_migrations).and_return([])
    allow(diagnostics).to receive(:pending_migrations).and_return([])
    allow(task_runner).to receive(:invoke)
  end

  it "previews without invoking mutating Rake tasks" do
    result = described_class.new(
      io: output,
      dry_run: true,
      diagnostics_class:,
      task_runner:
    ).call

    expect(result).to be true
    expect(task_runner).not_to have_received(:invoke)
    expect(output.string).to include("DRY_RUN=1: no migrations were copied or run")
  end

  it "copies migrations, runs all host migrations, and performs postflight" do
    described_class.new(
      io: output,
      diagnostics_class:,
      task_runner:
    ).call

    expect(task_runner).to have_received(:invoke).with("railspress:install:migrations")
    expect(task_runner).to have_received(:invoke).with("db:migrate")
    expect(diagnostics).to have_received(:call).with(no_args)
    expect(output.string).to include("Running all pending host migrations")
    expect(output.string).to include("upgrade complete")
  end

  it "stops before mutation when preflight fails" do
    failure_report = Railspress::Diagnostics::Report.new([
      Railspress::Diagnostics::Finding.new(
        code: :configuration_invalid,
        severity: :failure,
        label: "Configuration",
        message: "invalid",
        remediation: nil
      )
    ])
    allow(diagnostics).to receive(:call).with(include_migrations: false).and_return(failure_report)

    expect {
      described_class.new(
        io: output,
        diagnostics_class:,
        task_runner:
      ).call
    }.to raise_error(Railspress::ConfigurationError, /preflight failed/)

    expect(task_runner).not_to have_received(:invoke)
  end

  it "stops before mutation in production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    expect {
      described_class.new(
        io: output,
        diagnostics_class:,
        task_runner:
      ).call
    }.to raise_error(Railspress::ConfigurationError, /does not mutate production/)

    expect(task_runner).not_to have_received(:invoke)
  end

  it "allows a read-only dry run in production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    result = described_class.new(
      io: output,
      dry_run: true,
      diagnostics_class:,
      task_runner:
    ).call

    expect(result).to be true
    expect(task_runner).not_to have_received(:invoke)
  end

  it "propagates migration failures and does not run postflight" do
    allow(task_runner).to receive(:invoke).with("railspress:install:migrations")
    allow(task_runner).to receive(:invoke).with("db:migrate").and_raise("migration failed")

    expect {
      described_class.new(
        io: output,
        diagnostics_class:,
        task_runner:
      ).call
    }.to raise_error("migration failed")

    expect(diagnostics).not_to have_received(:call).with(no_args)
  end
end
