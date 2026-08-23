# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "pathname"
require "stringio"
require "tmpdir"

RSpec.describe Railspress::Doctor do
  let(:initializer_report) do
    Railspress::Diagnostics::Report.new([
      Railspress::Diagnostics::Finding.new(
        code: :initializer,
        severity: :pass,
        label: "Initializer",
        message: "valid",
        remediation: nil
      )
    ])
  end

  let(:initializer_check) do
    instance_double(
      Railspress::Diagnostics::InitializerCheck,
      call: initializer_report,
      path: Rails.root.join("config/initializers/railspress.rb")
    )
  end

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

    status = described_class.new(
      boot:,
      diagnostics:,
      initializer_check:,
      io: output,
      error_io: error_output
    ).call

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

    status = described_class.new(
      diagnostics:,
      initializer_check:,
      io: output,
      error_io: error_output,
      logger:
    ).call

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

    status = described_class.new(
      boot:,
      initializer_check:,
      error_io: error_output,
      logger:,
      trace: true
    ).call

    expect(status).to eq(1)
    expect(error_output.string).to include("[ERROR] railspress:doctor threw RuntimeError - host application failed to boot")
    expect(error_output.string).to include(__FILE__)
  end

  it "reports initializer preflight failures without booting the application" do
    failure_report = Railspress::Diagnostics::Report.new([
      Railspress::Diagnostics::Finding.new(
        code: :initializer_invalid,
        severity: :failure,
        label: "Initializer",
        message: "invalid Ruby syntax",
        remediation: "Correct the initializer."
      )
    ])
    check = instance_double(
      Railspress::Diagnostics::InitializerCheck,
      call: failure_report,
      path: Rails.root.join("config/initializers/railspress.rb")
    )
    boot = instance_spy(Proc, call: nil)
    output = StringIO.new

    status = described_class.new(boot:, initializer_check: check, io: output).call

    expect(status).to eq(1)
    expect(boot).not_to have_received(:call)
    expect(output.string).to include("[FAIL] Initializer: invalid Ruby syntax")
  end

  it "identifies settings that raise while the initializer is evaluated" do
    Dir.mktmpdir do |directory|
      initializer_path = Pathname(directory).join("config/initializers/railspress.rb")
      FileUtils.mkdir_p(initializer_path.dirname)
      initializer_path.write("# valid Ruby\n")
      check = instance_double(
        Railspress::Diagnostics::InitializerCheck,
        call: initializer_report,
        path: initializer_path
      )
      boot = -> { eval("raise NoMethodError, 'unknown setting'", binding, initializer_path.to_s) }
      output = StringIO.new
      error_output = StringIO.new

      status = described_class.new(
        boot:,
        initializer_check: check,
        io: output,
        error_io: error_output
      ).call

      expect(status).to eq(1)
      expect(output.string).to include(
        "[FAIL] Initializer: config/initializers/railspress.rb raised NoMethodError: unknown setting"
      )
      expect(error_output.string).to be_empty
    end
  end
end
