namespace :railspress do
  desc "Inspect RailsPress configuration, mount, encryption, and migrations"
  task :doctor do
    Railspress.with_validation_reporting do
      Rake::Task["environment"].invoke
    end

    report = Railspress::Diagnostics.new.call
    report.render
    raise Railspress::ConfigurationError, "RailsPress doctor found failures" if report.failures?
  end

  desc "Copy RailsPress migrations, migrate the host database, and verify the upgrade"
  task :upgrade do
    Railspress.with_validation_reporting do
      Rake::Task["environment"].invoke
    end

    dry_run = %w[1 true yes].include?(ENV.fetch("DRY_RUN", "").downcase)
    Railspress::Upgrade.new(dry_run:).call
  end
end
