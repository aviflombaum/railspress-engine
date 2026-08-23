# frozen_string_literal: true

require "rake"

module Railspress
  class Upgrade
    class RakeTaskRunner
      def invoke(task_name)
        Rake::Task[task_name].invoke
      end
    end

    def initialize(application: Rails.application, io: $stdout, dry_run: false,
      diagnostics_class: Railspress::Diagnostics, task_runner: RakeTaskRunner.new)
      @application = application
      @io = io
      @dry_run = dry_run
      @diagnostics_class = diagnostics_class
      @task_runner = task_runner
    end

    def call
      print_header
      guard_production!

      diagnostics = diagnostics_class.new(application: application)
      preflight = diagnostics.call(include_migrations: false)
      preflight.render(io:, title: "RailsPress upgrade preflight")
      raise Railspress::ConfigurationError, "RailsPress upgrade preflight failed" if preflight.failures?

      print_migration_inventory(diagnostics)
      return print_dry_run_result if dry_run

      io.puts "==> Copying RailsPress migrations"
      task_runner.invoke("railspress:install:migrations")

      refreshed_diagnostics = diagnostics_class.new(application: application)
      print_pending_host_migrations(refreshed_diagnostics)

      io.puts "==> Running all pending host migrations"
      task_runner.invoke("db:migrate")

      postflight = diagnostics_class.new(application: application).call
      postflight.render(io:, title: "RailsPress upgrade postflight")
      raise Railspress::ConfigurationError, "RailsPress upgrade postflight failed" if postflight.failures?

      io.puts "RailsPress #{Railspress::VERSION} upgrade complete."
      true
    end

    private

    attr_reader :application, :io, :dry_run, :diagnostics_class, :task_runner

    def print_header
      io.puts "RailsPress #{Railspress::VERSION} upgrade"
      io.puts "Environment: #{Rails.env}"
      io.puts
    end

    def guard_production!
      return unless Rails.env.production? && !dry_run

      raise Railspress::ConfigurationError,
        "railspress:upgrade does not mutate production. Run it in a development checkout, " \
        "review and commit copied migrations, deploy them, then use the host's normal bin/rails db:migrate step."
    end

    def print_migration_inventory(diagnostics)
      uncopied = diagnostics.uncopied_migrations
      if uncopied.empty?
        io.puts "RailsPress migrations to copy: none"
      else
        io.puts "RailsPress migrations to copy:"
        uncopied.each { |name| io.puts "  - #{name}" }
      end
      print_pending_host_migrations(diagnostics)
      io.puts
    end

    def print_pending_host_migrations(diagnostics)
      pending = diagnostics.pending_migrations
      if pending.empty?
        io.puts "Pending host migrations currently visible: none"
      else
        io.puts "Pending host migrations currently visible (db:migrate runs all of them):"
        pending.each { |migration| io.puts "  - #{migration.version} #{migration.name}" }
      end
    end

    def print_dry_run_result
      io.puts "DRY_RUN=1: no migrations were copied or run."
      true
    end
  end
end
