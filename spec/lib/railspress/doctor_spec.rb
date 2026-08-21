# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe Railspress::Doctor do
  it "renders diagnostic failures and returns their status without raising" do
    report = Railspress::Diagnostics::Report.new([
      Railspress::Diagnostics::Finding.new(
        code: :configuration,
        severity: :failure,
        label: "Configuration",
        message: "is invalid",
        remediation: "Correct the initializer."
      )
    ])
    diagnostics = instance_double(Railspress::Diagnostics, call: report)
    output = StringIO.new
    error_output = StringIO.new
    boot = instance_spy(Proc, call: nil)

    status = described_class.new(boot:, diagnostics:, io: output, error_io: error_output).call

    expect(status).to eq(1)
    expect(boot).to have_received(:call)
    expect(output.string).to include("[FAIL] Configuration: is invalid")
    expect(output.string).to include("Suggestion: Correct the initializer.")
    expect(error_output.string).to be_empty
  end

  it "reports and logs unexpected errors without raising them" do
    diagnostics = instance_double(Railspress::Diagnostics)
    allow(diagnostics).to receive(:call).and_raise(RuntimeError, "database exploded")
    logger = instance_double(ActiveSupport::Logger, error: nil)
    output = StringIO.new
    error_output = StringIO.new

    status = described_class.new(diagnostics:, io: output, error_io: error_output, logger:).call

    expect(status).to eq(1)
    expect(output.string).to be_empty
    expect(error_output.string).to include("[ERROR] railspress:doctor threw RuntimeError - database exploded")
    expect(error_output.string).to include("Suggestion: Correct the underlying error")
    expect(error_output.string).not_to include("doctor_spec.rb")
    expect(logger).to have_received(:error).with(/RuntimeError - database exploded/)
  end

  it "prints an unexpected error backtrace when trace output is requested" do
    error_output = StringIO.new
    logger = instance_double(ActiveSupport::Logger, error: nil)
    boot = -> { raise "host application failed to boot" }

    status = described_class.new(boot:, error_io: error_output, logger:, trace: true).call

    expect(status).to eq(1)
    expect(error_output.string).to include("[ERROR] railspress:doctor threw RuntimeError - host application failed to boot")
    expect(error_output.string).to include(__FILE__)
  end
end
