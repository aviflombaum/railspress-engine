# Releasing RailsPress

Use this checklist when cutting a new gem release.

## 1. Preflight

- Confirm `lib/railspress/version.rb` is set to the target version.
- Confirm `CHANGELOG.md` has an `Unreleased` entry covering the release changes.
- Move the Unreleased entries under the target version/date and add explicit upgrade notes, including migration and configuration impact.
- Review `docs/UPGRADING.md`, `docs/MAINTENANCE.md`, API docs, and generator instructions against the release diff.
- Verify the working tree contains no accidental generated migrations, credentials, tokens, or build artifacts.
- Run dependency refresh:

```bash
bundle lock
```

## 2. Verify

Run at least:

```bash
bundle exec rspec
bin/rubocop
bin/rails -T railspress
bin/rails railspress:doctor
bin/rails routes -g railspress
```

Run focused specs for changed areas before the full suite. Also run the documentation contract spec, which checks local Markdown links and selected code/documentation inventories.

The doctor command may report authentication warnings in the dummy app; investigate definite failures and confirm its exit status matches the report. Confirm interactive output uses the documented colors, redirected output contains no ANSI escapes, and each warning or failure includes a suggestion. Review the route output for the documented admin and API helpers.

## 3. Build Artifact

```bash
gem build railspress.gemspec
```

This should produce `railspress-engine-<version>.gem`.

Inspect the artifact before publishing:

```bash
gem specification railspress-engine-<version>.gem --yaml
```

Confirm it contains `README.md`, `CHANGELOG.md`, `docs/`, migrations, tasks, generators/templates, runtime code, and assets. Confirm it does not contain specs, the dummy app, plans, local credentials, or temporary files.

## 4. Commit and Push Release Commit

```bash
git add .
git commit -m "Release v<version>"
git push origin main
```

## 5. Publish Gem

```bash
gem push railspress-engine-<version>.gem
```

## 6. Tag and Publish GitHub Release

```bash
git tag v<version>
git push origin v<version>
```

## 7. Post-Release

- Create GitHub release notes from `CHANGELOG.md`.
- Verify installation in a fresh Rails app using the built gem, including a boot, the complete RailsPress migration history, signed-out admin-auth check, and any enabled API encryption setup. Keep Agents & API disabled for one verification run and confirm its migrations are still copied, applied, and accepted by doctor:

```bash
bundle add railspress-engine --version <version>
bin/rails generate railspress:install
bin/rails db:migrate
bin/rails railspress:doctor
```

- Verify an upgrade from the previous released gem in a separate disposable host: update the gem, run `DRY_RUN=1 bin/rails railspress:upgrade`, copy/review migrations, run the normal upgrade, and exercise affected admin/API behavior.
- Verify documentation links render correctly in the repository and installed gem.
- Push the release commit and tag only after the RubyGems and GitHub metadata agree on the version.
