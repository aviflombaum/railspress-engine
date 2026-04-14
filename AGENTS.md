# Repository Guidelines

## Project Structure & Module Organization
RailsPress is a mountable Rails engine with an isolated `Railspress` namespace.

- `app/` engine runtime code (`models/railspress`, `controllers/railspress/admin`, `views`, `jobs`, `services`, Stimulus controllers in `app/javascript/railspress/controllers`)
- `lib/` engine boot/config (`lib/railspress/engine.rb`), generators, and rake tasks
- `db/migrate/` engine migrations shipped with the gem
- `spec/` RSpec tests, fixtures, and `spec/dummy/` host app used for integration testing
- `docs/` user and maintainer guides (configuration, theming, import/export, upgrading)

## Build, Test, and Development Commands
Run from engine root unless noted.

- `bundle install` install Ruby dependencies
- `bundle exec rspec` run full test suite
- `bundle exec rspec spec/models/railspress/post_spec.rb` run one spec file
- `bundle exec rspec spec/models/railspress/post_spec.rb:15` run one example by line
- `bin/rubocop` lint with Omakase Rails rules
- `bin/rubocop -a` auto-fix safe offenses
- `cd spec/dummy && bin/rails db:migrate` migrate dummy app DB for integration specs
- `bundle exec rake` default task (aliases to `spec`)

## Coding Style & Naming Conventions
- Ruby style follows `rubocop-rails-omakase` (`.rubocop.yml`); use 2-space indentation.
- Keep engine code namespaced under `Railspress::`.
- Place admin controllers under `Railspress::Admin::*` inheriting from admin base controllers.
- Stimulus controllers should end in `_controller.js` and be registered in `app/javascript/railspress/controllers/index.js`.
- CSS uses BEM-like classes with `rp-` prefix.

## Testing Guidelines
- Framework: RSpec (`rspec-rails`) with fixtures (not factories).
- Fixture files live in `spec/fixtures/`.
- Request/system behavior should be validated against the dummy app when relevant.
- Add/adjust specs with each behavior change; prefer model/request coverage plus system specs for admin UI regressions.

## Commit & Pull Request Guidelines
- Recent history favors short, imperative subjects (for example, `Fix inline editor opacity issue`, `Update README...`).
- Use clear commit subjects, ideally `<area>: <imperative change>` under ~72 chars; avoid vague messages.
- PRs should include: purpose, key changes, test coverage notes, and migration impact.
- Link related issues and include screenshots/GIFs for admin UI or inline-editing changes.

## Security & Configuration Tips
The admin interface is public by default until host-app auth is added. Before release, gate `/railspress/admin` (see `docs/CONFIGURING.md`) and verify ActionText/Active Storage are installed.
