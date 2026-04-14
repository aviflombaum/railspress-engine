# Releasing RailsPress

Use this checklist when cutting a new gem release.

## 1. Preflight

- Confirm `lib/railspress/version.rb` is set to the target version.
- Confirm `CHANGELOG.md` has an `Unreleased` entry covering the release changes.
- Run dependency refresh:

```bash
bundle lock
```

## 2. Verify

Run at least:

```bash
bundle exec rspec
bin/rubocop
```

If needed, run focused specs for changed areas before the full suite.

## 3. Build Artifact

```bash
gem build railspress.gemspec
```

This should produce `railspress-engine-<version>.gem`.

## 4. Tag and Publish (after verification)

```bash
git add .
git commit -m "Release v<version>"
git tag v<version>
git push origin main --tags
gem push railspress-engine-<version>.gem
```

## 5. Post-Release

- Create GitHub release notes from `CHANGELOG.md`.
- Verify installation in a fresh Rails app:

```bash
bundle add railspress-engine --version <version>
bin/rails generate railspress:install
bin/rails db:migrate
```
