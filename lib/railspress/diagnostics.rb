# frozen_string_literal: true

require "pathname"
require "ripper"

module Railspress
  class Diagnostics
    Finding = Data.define(:code, :severity, :label, :message, :remediation)

    LEXXY_PIN_PATTERN = /^\s*pin\s+["']lexxy["'](?:\s*,|\s*$)/
    LEXXY_IMPORT_PATTERN = /^\s*import\s+(?:.+?\s+from\s+)?["']lexxy["']\s*;?(?:\s*\/\/.*)?$/

    class Report
      ANSI = {
        bold: "\e[1m",
        pass: "\e[32m",
        warning: "\e[33m",
        failure: "\e[31m",
        reset: "\e[0m"
      }.freeze

      attr_reader :findings

      def initialize(findings)
        @findings = findings.freeze
      end

      def failures?
        findings.any? { |finding| finding.severity == :failure }
      end

      def exit_status
        failures? ? 1 : 0
      end

      def render(io: $stdout, title: "RailsPress doctor #{Railspress::VERSION}", color: nil)
        color = color_output?(io) if color.nil?

        io.puts colorize(title, :bold, color:)
        io.puts
        findings.each do |finding|
          status = colorize("[#{status_label(finding.severity)}]", finding.severity, color:)
          io.puts "#{status} #{finding.label}: #{finding.message}"
          render_suggestion(io, finding) unless finding.severity == :pass
        end
        io.puts
        io.puts colorize(summary, summary_severity, color:)
        io.puts conclusion
      end

      private

      def status_label(severity)
        { pass: "PASS", warning: "WARN", failure: "FAIL" }.fetch(severity)
      end

      def render_suggestion(io, finding)
        suggestion = finding.remediation.presence || default_suggestion(finding.severity)
        io.puts "       Suggestion: #{suggestion}"
      end

      def default_suggestion(severity)
        if severity == :failure
          "Correct this failure and rerun bin/rails railspress:doctor."
        else
          "Review this warning and confirm the behavior is intentional."
        end
      end

      def color_output?(io)
        ENV["NO_COLOR"].blank? && io.respond_to?(:tty?) && io.tty?
      end

      def colorize(text, style, color:)
        return text unless color

        "#{ANSI.fetch(style)}#{text}#{ANSI.fetch(:reset)}"
      end

      def summary_severity
        return :failure if failures?
        return :warning if findings.any? { |finding| finding.severity == :warning }

        :pass
      end

      def conclusion
        if failures?
          "Doctor found failures that require action. Apply the suggestions above and rerun the command."
        elsif findings.any? { |finding| finding.severity == :warning }
          "Doctor completed without failures. Review the warnings above."
        else
          "Doctor found no problems."
        end
      end

      def summary
        counts = findings.map(&:severity).tally
        [
          pluralize(counts.fetch(:failure, 0), "failure"),
          pluralize(counts.fetch(:warning, 0), "warning"),
          pluralize(counts.fetch(:pass, 0), "pass", "passes")
        ].join(", ")
      end

      def pluralize(count, singular, plural = nil)
        "#{count} #{count == 1 ? singular : (plural || "#{singular}s")}"
      end
    end

    class InitializerCheck
      attr_reader :path, :logger

      def initialize(app_root: Rails.root, logger: Rails.logger)
        @path = Pathname(app_root).join("config/initializers/railspress.rb")
        @logger = logger
      end

      def call
        return Report.new([ missing_finding ]) unless path.file?

        source = path.read
        syntax_error = syntax_error_for(source)
        return Report.new([ invalid_finding(syntax_error) ]) if syntax_error

        Report.new([
          Finding.new(
            code: :initializer,
            severity: :pass,
            label: "Initializer",
            message: "config/initializers/railspress.rb is present and valid Ruby",
            remediation: nil
          )
        ])
      rescue SystemCallError => error
        logger.error "RailsPress doctor could not read #{path}: #{error.message}"
        Report.new([
          Finding.new(
            code: :initializer_unreadable,
            severity: :failure,
            label: "Initializer",
            message: "could not read config/initializers/railspress.rb: #{error.message}",
            remediation: "Fix the file permissions and rerun bin/rails railspress:doctor."
          )
        ])
      end

      private

      def syntax_error_for(source)
        if defined?(RubyVM::InstructionSequence)
          RubyVM::InstructionSequence.compile(source, path.to_s)
        elsif Ripper.sexp(source).nil?
          return "Ruby could not parse the file"
        end

        nil
      rescue SyntaxError => error
        logger.error "RailsPress doctor found invalid initializer syntax in #{path}: #{error.message}"
        error.message.lines.first.to_s.strip
      end

      def missing_finding
        Finding.new(
          code: :initializer_missing,
          severity: :warning,
          label: "Initializer",
          message: "config/initializers/railspress.rb is missing; RailsPress is using library defaults",
          remediation: "Run bin/rails generate railspress:install or create the initializer from the configuration guide."
        )
      end

      def invalid_finding(message)
        Finding.new(
          code: :initializer_invalid,
          severity: :failure,
          label: "Initializer",
          message: "config/initializers/railspress.rb has invalid Ruby syntax: #{message}",
          remediation: "Correct the initializer syntax and rerun bin/rails railspress:doctor."
        )
      end
    end

    def initialize(application: Rails.application, engine_root: Railspress::Engine.root, app_root: Rails.root,
      migration_context: nil)
      @application = application
      @engine_root = Pathname(engine_root)
      @app_root = Pathname(app_root)
      @migration_context = migration_context
    end

    def call(include_migrations: true)
      findings = []
      findings.concat(configuration_findings)
      findings.concat(admin_authentication_findings)
      findings.concat(current_admin_findings)
      findings.concat(encryption_findings)
      findings.concat(mount_findings)
      findings.concat(lexxy_wiring_findings)
      findings.concat(deprecation_findings)
      findings.concat(migration_findings) if include_migrations
      Report.new(findings)
    end

    def uncopied_migrations
      engine_migration_names - host_migration_names
    end

    def pending_migrations
      pending_versions = migration_context.pending_migration_versions
      migration_context.migrations.select { |migration| pending_versions.include?(migration.version) }
    end

    private

    attr_reader :application, :engine_root, :app_root

    def configuration_findings
      errors = Railspress.configuration.validation_errors
      if errors.empty?
        [ finding(:configuration, :pass, "Configuration", enabled_feature_summary) ]
      else
        errors.map do |message|
          finding(:configuration_invalid, :failure, "Configuration", message)
        end
      end
    end

    def enabled_feature_summary
      features = []
      features << "authors" if Railspress.authors_enabled?
      features << "post images" if Railspress.post_images_enabled?
      features << "focal points" if Railspress.focal_points_enabled?
      features << "CMS" if Railspress.cms_enabled?
      features << "Agents & API" if Railspress.api_enabled?
      features.any? ? "enabled features: #{features.join(", ")}" : "using core blog features"
    end

    def admin_authentication_findings
      concern_finding = admin_auth_concern_finding
      method_name = Railspress.admin_authentication_method

      return [ concern_finding ].compact if method_name.blank? && concern_finding&.severity == :pass

      if method_name.blank?
        findings = [
          finding(
            :admin_authentication_implicit,
            :warning,
            "Admin authentication",
            "no explicit admin_authentication_method is configured; inherited callbacks, middleware, and proxies cannot be verified",
            "Verify signed-out access to #{admin_path} or configure config.admin_authentication_method."
          )
        ]
        findings << concern_finding if concern_finding
        findings
      elsif controller_method_callable?(method_name)
        findings = [
          finding(:admin_authentication, :pass, "Admin authentication", "#{method_name.inspect} is callable")
        ]
        findings << concern_finding if concern_finding
        findings
      else
        findings = [
          finding(
            :admin_authentication_method_missing,
            :failure,
            "Admin authentication",
            "#{method_name.inspect} is configured but Railspress::Admin::BaseController cannot call it",
            "Define the method on the host ApplicationController or change config.admin_authentication_method."
          )
        ]
        findings << concern_finding if concern_finding
        findings
      end
    end

    def admin_auth_concern_finding
      configured_concern = Railspress.admin_auth_concern
      return if configured_concern.blank?

      concern = resolve_concern(configured_concern)
      unless concern
        return finding(
          :admin_auth_concern_invalid,
          :failure,
          "Admin auth concern",
          "#{configured_concern.inspect} does not resolve to a Module",
          "Define the concern or change config.admin_auth_concern."
        )
      end

      if Railspress::Admin::BaseController < concern
        finding(:admin_auth_concern, :pass, "Admin auth concern", "#{concern.name || concern.inspect} is included")
      else
        finding(
          :admin_auth_concern_not_included,
          :failure,
          "Admin auth concern",
          "#{concern.name || concern.inspect} resolved but is not included in Railspress::Admin::BaseController",
          "Check the RailsPress admin auth concern initializer and application reload hooks."
        )
      end
    end

    def resolve_concern(value)
      return value if value.is_a?(Module)
      return unless value.is_a?(String) || value.is_a?(Symbol)

      name = value.to_s
      resolved = name.safe_constantize || name.camelize.safe_constantize
      resolved if resolved.is_a?(Module)
    end

    def current_admin_findings
      return [] unless Railspress.api_enabled?

      if Railspress.current_admin_proc
        [ finding(:current_admin, :pass, "Current admin", "current_admin_proc is configured") ]
      elsif controller_method_callable?(Railspress.current_admin_method)
        [ finding(:current_admin, :pass, "Current admin", "#{Railspress.current_admin_method.inspect} is callable") ]
      else
        [
          finding(
            :current_admin_method_missing,
            :failure,
            "Current admin",
            "#{Railspress.current_admin_method.inspect} is configured but Railspress::Admin::BaseController cannot call it",
            "Configure config.current_admin_method or config.current_admin_proc for API key auditing."
          )
        ]
      end
    end

    def controller_method_callable?(method_name)
      return false if method_name.blank?

      controller_class = Railspress::Admin::BaseController
      controller_class.method_defined?(method_name) || controller_class.private_method_defined?(method_name)
    end

    def encryption_findings
      return [ finding(:api_encryption, :pass, "API encryption", "not required because Agents & API is disabled") ] unless Railspress.api_enabled?

      encryption = Railspress::ActiveRecordEncryptionConfiguration.new(application)
      if encryption.configured?
        [ finding(:api_encryption, :pass, "API encryption", "all required values are present") ]
      else
        [
          finding(
            :api_encryption_missing,
            :failure,
            "API encryption",
            "missing #{encryption.missing_keys.join(", ")}",
            "Run `#{Railspress::ActiveRecordEncryptionConfiguration::SETUP_COMMAND}` and store the values in host credentials."
          )
        ]
      end
    end

    def mount_findings
      mounts = application.routes.routes.filter_map { |route| mount_details(route) }
      return [
        finding(
          :mount_missing,
          :warning,
          "Mount",
          "Railspress::Engine is not mounted",
          "Mount Railspress::Engine in config/routes.rb if the host serves RailsPress routes."
        )
      ] if mounts.empty?

      findings = mounts.map do |mount|
        constraint_names = mount[:constraints].map { |constraint| constraint_name(constraint) }
        if constraint_names.empty?
          finding(:mount, :pass, "Mount", mount[:path])
        else
          api_detail = Railspress.api_enabled? ? "; verify bearer-token API requests reach RailsPress" : ""
          finding(
            :mount_constrained,
            :warning,
            "Mount",
            "#{mount[:path]} is wrapped by #{constraint_names.join(", ")}#{api_detail}",
            "Prefer a normal mount with controller-level admin authentication."
          )
        end
      end

      if mounts.many?
        findings << finding(
          :mount_multiple,
          :warning,
          "Mount",
          "RailsPress is mounted #{mounts.length} times: #{mounts.map { |mount| mount[:path] }.join(", ")}",
          "Verify each mount has the intended authentication and API behavior."
        )
      end
      findings
    end

    def mount_details(route)
      current_app = route.app
      constraints = []
      visited = {}

      while current_app && !visited[current_app.object_id]
        visited[current_app.object_id] = true
        constraints.concat(Array(current_app.constraints)) if current_app.respond_to?(:constraints)
        nested_app = current_app.respond_to?(:app) ? current_app.app : nil
        return { path: route.path.spec.to_s, constraints: constraints } if nested_app == Railspress::Engine
        current_app = nested_app
      end
    end

    def constraint_name(constraint)
      constraint.is_a?(Module) ? constraint.name : constraint.class.name
    end

    def admin_path
      mount = application.routes.routes.filter_map { |route| mount_details(route) }.first
      "#{mount ? mount[:path].delete_suffix("/") : "/railspress"}/admin"
    end

    def lexxy_wiring_findings
      importmap_path = app_root.join("config/importmap.rb")
      return [] unless importmap_path.file?

      references = []
      references << "config/importmap.rb" if file_contains?(importmap_path, LEXXY_PIN_PATTERN)

      application_js_path = app_root.join("app/javascript/application.js")
      if application_js_path.file? && file_contains?(application_js_path, LEXXY_IMPORT_PATTERN)
        references << "app/javascript/application.js"
      end

      if references.empty?
        [ finding(:lexxy_wiring, :pass, "Lexxy wiring", "managed by RailsPress") ]
      else
        paths = references.to_sentence
        [
          finding(
            :lexxy_wiring_redundant,
            :warning,
            "Lexxy wiring",
            "host references engine-managed Lexxy in #{paths}",
            "Remove the redundant Lexxy reference from #{paths}; keep a host pin only when intentionally overriding the engine-managed asset."
          )
        ]
      end
    rescue SystemCallError => error
      [
        finding(
          :lexxy_wiring_unreadable,
          :warning,
          "Lexxy wiring",
          "could not inspect host JavaScript configuration: #{error.message}",
          "Verify that config/importmap.rb and app/javascript/application.js are readable, then rerun doctor."
        )
      ]
    end

    def file_contains?(path, pattern)
      path.each_line.any? { |line| line.match?(pattern) }
    end

    def deprecation_findings
      settings = Railspress.configuration.deprecated_settings
      return [] if settings.empty?

      [
        finding(
          :deprecated_settings,
          :warning,
          "Deprecated configuration",
          settings.map { |setting| "config.#{setting}" }.join(", "),
          "Replace deprecated settings using docs/UPGRADING.md before RailsPress 2.0."
        )
      ]
    end

    def migration_findings
      findings = if uncopied_migrations.empty?
        [ finding(:migrations_copied, :pass, "Migrations", "all RailsPress migrations are copied") ]
      else
        [
          finding(
            :migrations_uncopied,
            :failure,
            "Migrations",
            "not copied (all shipped migrations are required, even for disabled features): #{uncopied_migrations.join(", ")}",
            "Run bin/rails railspress:install:migrations, review the copied files, run bin/rails db:migrate, then rerun doctor."
          )
        ]
      end

      pending = pending_railspress_migrations
      if pending.empty?
        findings << finding(:migrations_current, :pass, "Database", "no copied RailsPress migrations are pending")
      else
        findings << finding(
          :migrations_pending,
          :failure,
          "Database",
          "pending RailsPress migrations: #{pending.map { |migration| migration.name.underscore }.join(", ")}",
          "Review the pending migrations, run bin/rails db:migrate, then rerun doctor."
        )
      end
      findings
    rescue ActiveRecord::ActiveRecordError => error
      Rails.logger.error "RailsPress doctor could not inspect migrations: #{error.message}"
      [
        finding(
          :migration_inspection_failed,
          :failure,
          "Database",
          "could not inspect migration state: #{error.message}",
          "Verify the database configuration and connection, then run doctor again."
        )
      ]
    end

    def migration_context
      @migration_context ||= ActiveRecord::Base.connection_pool.migration_context
    end

    def pending_railspress_migrations
      pending_migrations.select { |migration| host_migration?(migration.filename) }
    end

    def engine_migration_names
      @engine_migration_names ||= Dir[engine_root.join("db/migrate/*.rb")].map { |path| migration_name(path) }.sort
    end

    def host_migration_names
      Dir[host_migration_directory.join("*.rb")].map { |path| migration_name(path) }.sort
    end

    def host_migration?(filename)
      Pathname(filename).expand_path.to_s.start_with?("#{host_migration_directory.expand_path}/") &&
        engine_migration_names.include?(migration_name(filename))
    end

    def host_migration_directory
      app_root.join("db/migrate")
    end

    def migration_name(path)
      File.basename(path)
        .sub(/\A\d+_/, "")
        .sub(/\.railspress\.rb\z/, "")
        .sub(/\.rb\z/, "")
    end

    def finding(code, severity, label, message, remediation = nil)
      Finding.new(code:, severity:, label:, message:, remediation:)
    end
  end
end
