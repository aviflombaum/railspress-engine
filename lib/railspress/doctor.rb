# frozen_string_literal: true

module Railspress
  class Doctor
    ERROR_COLOR = "\e[31m"
    COLOR_RESET = "\e[0m"

    def initialize(boot: -> { }, diagnostics: nil, initializer_check: nil, io: $stdout, error_io: $stderr,
      logger: Rails.logger, trace: false)
      @boot = boot
      @diagnostics = diagnostics
      @initializer_check = initializer_check
      @io = io
      @error_io = error_io
      @logger = logger
      @trace = trace
    end

    def call
      initializer_report = resolved_initializer_check.call
      if initializer_report.failures?
        initializer_report.render(io:)
        return initializer_report.exit_status
      end

      boot.call
      report = (diagnostics || Railspress::Diagnostics.new).call
      combined_report = Railspress::Diagnostics::Report.new(initializer_report.findings + report.findings)
      combined_report.render(io:)
      combined_report.exit_status
    rescue StandardError => error
      return render_initializer_error(error) if initializer_error?(error)

      render_error(error)
      1
    end

    private

    attr_reader :boot, :diagnostics, :initializer_check, :io, :error_io, :logger, :trace

    def resolved_initializer_check
      @resolved_initializer_check ||= initializer_check || Railspress::Diagnostics::InitializerCheck.new
    end

    def initializer_error?(error)
      initializer_path = resolved_initializer_check.path.to_s
      Array(error.backtrace_locations).any? do |location|
        (location.absolute_path || location.path) == initializer_path
      end
    end

    def render_initializer_error(error)
      logger.error(
        "RailsPress initializer failed with #{error.class}: #{error.message}\n" \
          "#{Array(error.backtrace).join("\n")}"
      )
      report = Railspress::Diagnostics::Report.new([
        Railspress::Diagnostics::Finding.new(
          code: :initializer_error,
          severity: :failure,
          label: "Initializer",
          message: "config/initializers/railspress.rb raised #{error.class}: #{error.message}",
          remediation: "Correct the initializer setting and rerun bin/rails railspress:doctor."
        )
      ])
      report.render(io:)
      report.exit_status
    end

    def render_error(error)
      message = "railspress:doctor threw #{error.class} - #{error.message}"
      logger.error("#{message}\n#{Array(error.backtrace).join("\n")}")

      error_io.puts "#{colorize("[ERROR]")} #{message}"
      error_io.puts "Suggestion: Correct the underlying error and rerun bin/rails railspress:doctor. Use --trace for a backtrace."
      error_io.puts error.full_message if trace
    end

    def colorize(text)
      return text unless ENV["NO_COLOR"].blank? && error_io.respond_to?(:tty?) && error_io.tty?

      "#{ERROR_COLOR}#{text}#{COLOR_RESET}"
    end
  end
end
