# frozen_string_literal: true

module Railspress
  class Doctor
    ERROR_COLOR = "\e[31m"
    COLOR_RESET = "\e[0m"

    def initialize(boot: -> { }, diagnostics: nil, io: $stdout, error_io: $stderr, logger: Rails.logger,
      trace: false)
      @boot = boot
      @diagnostics = diagnostics
      @io = io
      @error_io = error_io
      @logger = logger
      @trace = trace
    end

    def call
      boot.call
      report = (diagnostics || Railspress::Diagnostics.new).call
      report.render(io:)
      report.exit_status
    rescue StandardError => error
      render_error(error)
      1
    end

    private

    attr_reader :boot, :diagnostics, :io, :error_io, :logger, :trace

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
