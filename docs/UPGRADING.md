# Upgrading RailsPress

This guide covers upgrading the RailsPress engine between versions.

## Upgrading to 1.4.5

RailsPress admin controllers now inherit the host application's `ApplicationController`. Mount the engine normally and configure the host methods RailsPress should use:

```ruby
Railspress.configure do |config|
  config.admin_authentication_method = :require_admin!
  config.current_admin_method = :current_user
end
```

`admin_authentication_method` is optional only when an inherited host callback already protects RailsPress. Verify this with a signed-out request: RailsPress can confirm that an explicit method exists, but cannot prove the authorization behavior of inherited callbacks, middleware, or a reverse proxy.

API controllers remain on a separate `ActionController::API` stack and use bearer authentication, so remove session-only constraints wrapped around the entire engine mount. A rejected constraint can return `404` before API authentication runs. If a later catch-all route handles the miss, an API client can instead receive `200 text/html` with a login page. After remediation, an unauthenticated API request should reach RailsPress and return `401`, not `404` or successful HTML.

Rename `current_api_actor_method` to `current_admin_method`, `current_api_actor_proc` to `current_admin_proc`, and any controller-helper use of `current_api_actor` to `current_railspress_admin`. The old names continue to work with deprecation warnings in RailsPress 1.x and will be removed in RailsPress 2.0.

RailsPress now validates the Active Record Encryption prerequisite when Agents & API is enabled. Existing API-enabled hosts must provide `primary_key`, `deterministic_key`, and `key_derivation_salt` through Rails credentials or `config.active_record.encryption` in every deployed environment.

If credentials are missing, generate the standard Rails snippet and store its values in the host's credentials or deployment secret manager:

```bash
bin/rails db:encryption:init
```

RailsPress does not generate, persist, or overwrite these secrets. A missing value normally stops boot with `Railspress::ConfigurationError`. `bin/rails railspress:doctor` uses a narrow report-only boot mode so it can name RailsPress configuration failures without weakening normal application boot validation. Hosts that do not call `config.enable_api` are unaffected.

RailsPress now depends on `stimulus-rails >= 1.2.2` and serves its default Stimulus import locally instead of loading Stimulus from JSPM. Bundler will reuse a compatible host installation; applications pinned below 1.2.2 must upgrade that pin. Existing host importmap pins remain authoritative because the host map loads after the engine map. The Google Fonts import was also removed, so RailsPress admin display text now uses the local Georgia/system-serif stack.

No host importmap edit is required. Remove an old RailsPress-specific JSPM pin if the host does not intentionally manage Stimulus itself:

```ruby
# No longer needed for RailsPress:
pin "@hotwired/stimulus", to: "https://ga.jspm.io/..."
```

## Quick Upgrade

```bash
# 1. Update the gem
bundle update railspress-engine

# 2. Optionally preview configuration and migration work without writes
DRY_RUN=1 bin/rails railspress:upgrade

# 3. Copy RailsPress migrations, run migrations, and verify
bin/rails railspress:upgrade

# 4. Restart your server
```

The upgrade task runs `db:migrate`, so it applies **all pending host migrations**, not only RailsPress migrations. Its manual equivalent is:

```bash
bin/rails railspress:install:migrations
bin/rails db:migrate
bin/rails railspress:doctor
```

If Agents & API is enabled, confirm that the host already supplies all three Active Record Encryption settings before restarting. Run `bin/rails db:encryption:init` only when a value is missing, and store the generated values in the host's secret-management system. Never replace working production encryption credentials during a routine upgrade.

Also verify that `/railspress/admin/*` is protected through `config.admin_authentication_method` or an inherited host callback, while the engine itself is mounted without an outer session constraint.

### Production deployments

`railspress:upgrade` is a source-tree convenience task and refuses to mutate production. Run it in a writable development checkout, review and commit the generated `.railspress.rb` migration files, then deploy them with the host application. Production should use the host's normal release command:

```bash
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails railspress:doctor
```

The doctor command is read-only. It returns nonzero for definite configuration or migration failures and zero when it finds only warnings. Warnings about implicit authentication or route constraints require an operator to verify signed-out browser access and API behavior.

## Step-by-Step Guide

### 1. Update the Gem

If using a version constraint in your Gemfile:

```ruby
# Gemfile
gem "railspress-engine", "~> 1.0"
```

Run:

```bash
bundle update railspress-engine
```

If using a git source:

```ruby
# Gemfile
gem "railspress-engine", git: "https://github.com/aviflombaum/railspress-engine", branch: "main"
```

Run:

```bash
bundle update railspress-engine
```

### 2. Copy New Migrations

RailsPress includes a rake task to copy engine migrations to your application:

```bash
rails railspress:install:migrations
```

This copies any new migrations from the engine to your `db/migrate/` folder. Existing migrations are skipped (matched by migration name, not timestamp).

**Check what was copied:**

```bash
ls -la db/migrate/*railspress*
```

### 3. Review Migration Changes

Before running migrations, review them for any data implications:

```bash
# See pending migrations
rails db:migrate:status

# Preview a specific migration
cat db/migrate/TIMESTAMP_create_railspress_exports.rb
```

### 4. Run Migrations

```bash
rails db:migrate
```

For production, consider running migrations separately from deployment:

```bash
# Production
RAILS_ENV=production rails db:migrate
```

### 5. Check Configuration

New versions may add configuration options. Review the initializer:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.author_class_name = "User"
  config.author_display_method = :name

  config.enable_post_images
end
```

Check the [CONFIGURING.md](CONFIGURING.md) guide for new options.

### 6. Restart Application

```bash
# Development
rails restart

# Production (example with Puma)
pumactl restart
```

## Migration Internals

### How Engine Migrations Work

RailsPress migrations live in `railspress/db/migrate/`. When you run `railspress:install:migrations`, Rails copies them to your app with new timestamps.

Engine migration:
```
railspress/db/migrate/20241218000001_create_railspress_categories.rb
```

Becomes in your app:
```
db/migrate/20241224123456_create_railspress_categories.railspress.rb
```

The `.railspress` suffix tracks the migration origin.

### Migration Naming Convention

RailsPress uses a fixed timestamp prefix pattern:

| Timestamp | Migration |
|-----------|-----------|
| `20241218000001` | create_railspress_categories |
| `20241218000002` | create_railspress_tags |
| `20241218000003` | create_railspress_posts |
| `20241218000004` | create_railspress_post_tags |
| `20241218000005` | create_railspress_imports |
| `20241218000006` | create_railspress_exports |
| `20260415000001` | create_railspress_api_keys |

New migrations increment the suffix (000007, 000008, etc.).

### Checking Migration Status

```bash
# See all migrations and their status
rails db:migrate:status

# Filter to RailsPress migrations
rails db:migrate:status | grep railspress
```

### Rolling Back

If needed, rollback a specific migration:

```bash
# Rollback last migration
rails db:rollback

# Rollback to specific version
rails db:migrate:down VERSION=20241224123456
```

## Troubleshooting

### "Migration already exists"

If the rake task reports migrations already exist, they've been copied before. Check:

```bash
ls db/migrate/*railspress*
```

### Schema Mismatch

If your schema differs from expected migrations:

```bash
# Check current schema
rails db:schema:dump
cat db/schema.rb | grep railspress

# Compare with engine migrations
ls railspress/db/migrate/
```

### Missing Tables

If RailsPress tables are missing:

```bash
# Re-copy all migrations
rails railspress:install:migrations

# Run pending
rails db:migrate
```

### Duplicate Migrations

If you have duplicate migrations (same content, different timestamps):

1. Check which are already run: `rails db:migrate:status`
2. Delete the unrun duplicate
3. If both are run, the second likely failed silently

## Version-Specific Notes

### Upgrading to 1.4.4 (from 1.4.3)

RailsPress 1.4.4 hardens post imports without changing their supported file formats. Admin uploads now use server-generated storage names, and cleanup only removes canonical paths beneath the Rails temporary directory. ZIP image references must remain within their extraction directory.

Remote post header images now use `ssrf_filter`. Public HTTP and HTTPS images remain supported, but loopback, private, link-local, reserved, and redirected destinations are rejected.

Recommended upgrade flow:

```bash
bundle update railspress-engine
```

The engine installs `ssrf_filter` automatically. No migrations, initializer changes, or host application changes are required.

### Upgrading to 1.4.3 (from 1.4.2)

RailsPress 1.4.3 gives engine-owned search and pagination explicit names: `rp_search`, `rp_page`, and
`rp_per_page_count`. The engine admin uses only these methods, leaving host applications free to use
their own search scopes and pagination gems without relying on gem load order.

The older `search`, `page`, and `per_page_count` methods remain available through RailsPress 1.x when
the host model does not already provide them. Calls to these compatibility methods emit deprecation
warnings and should migrate to the corresponding `rp_*` method or to the host application's preferred
search and pagination API. The compatibility methods will be removed in RailsPress 2.0.

The built-in title search is also database-agnostic in 1.4.3. It uses adapter-aware Arel instead of
PostgreSQL-only `ILIKE` SQL.

Recommended upgrade flow:

```bash
bundle update railspress-engine
```

No migrations, initializer changes, or host application code changes are required immediately. New code
should avoid the deprecated generic method names.

### Upgrading to 1.4.2 (from 1.4.1)

RailsPress 1.4.2 updates CMS helper loading for compatibility with newer Rails versions. It preserves the Rails 8.1 load-order behavior while removing the `require_dependency` call deprecated in Rails 8.2 and scheduled for removal in Rails 9.

This release also raises its runtime floors to Rails `8.1.3.1`, Lexxy `0.9.29`, and image_processing `2.0.3`. RailsPress owns the Lexxy and image_processing dependencies, so do not add them to the host Gemfile. Applications using Vips must provide ruby-vips `2.2.1+` and system libvips `8.13+`.

Recommended upgrade flow:

```bash
bundle update railspress-engine
```

If Bundler reports a direct Rails version conflict, unlock Rails at the same time with `bundle update rails railspress-engine`. No migrations, initializer changes, or host application code changes are required.

If the application uses Vips, verify every deployed environment before restarting:

```bash
bundle exec ruby -e 'require "vips"; puts Vips::VERSION'
vips --version
```

The first version must be `2.2.1+`; the native libvips version must be `8.13+`. Rails 8.1.3.1 will refuse to boot with an older libvips because it cannot disable unsafe operations there.

Applications that previously accepted untrusted image uploads while using Vips on Rails earlier than 8.1.3.1 should follow the [Rails security advisory](https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm), including rotating application and service credentials that may have been exposed.

### Upgrading to 1.4.0 (from 1.3.x)

RailsPress 1.4.0 adopts Lexxy's first stable release and refreshes its dependency set.

Recommended upgrade flow:

```bash
bundle update railspress-engine lexxy
```

No migrations or host importmap changes are required. Keep `import "railspress"` in your host JavaScript entrypoint if you use host-page RailsPress features such as inline editing.

### Upgrading to 1.2.0 (from 1.0.0+)

This release improves Lexxy integration and upgrade behavior for host apps.

Key changes:
- Lexxy is now an open lower-bound dependency (`>= 0.9.0.beta`) instead of a pessimistic pin.
- Engine-managed importmap + RailsPress JS entrypoint handle Lexxy loading.
- Installer no longer adds a manual host `lexxy` importmap pin.
- Inline editor menu/backdrop rendering was hardened for pages with opacity/transform stacking contexts.
- ZIP import/export internals were updated for rubyzip 3 compatibility.
- Admin editor toolbar is sticky to improve long-form editing.

Recommended upgrade flow:

```bash
bundle update railspress-engine lexxy
rails railspress:install:migrations
rails db:migrate
```

JavaScript/config checklist:
- Keep/add `import "railspress"` in host `app/javascript/application.js` if you use host-page RailsPress features (inline editing, focal point controls, etc.).
- Remove manual host `pin "lexxy", to: "lexxy.js"` from `config/importmap.rb` unless you intentionally pin a specific Lexxy version.
- If you override RailsPress admin layout, include:

```erb
<script type="module">import "railspress"</script>
```

### Upgrading to 1.0.0

**New: Blocks (Content Element CMS), Inline Editing, and more**

This is a major release that introduces the third content pillar — Blocks — alongside Posts and Entities.

New migrations:
- `create_railspress_content_groups`
- `create_railspress_content_elements`
- `create_railspress_content_element_versions`

New features:
- **Blocks**: Content groups and elements for managing site copy and images
- **Inline CMS editing**: Right-click any `cms_element` to edit in place
- **Image content elements**: Text or image type with dropzone upload and focal point cropping
- **Auto-versioning**: Full audit trail for every content element edit
- **CMS export/import**: Sync content groups across environments as ZIP files
- **Soft deletion**: Content groups use non-destructive deletion

New configuration:
```ruby
Railspress.configure do |config|
  config.enable_cms                    # Enable Blocks
  config.inline_editing_check = ->(ctx) { ctx.controller.current_user&.admin? }
end
```

After upgrade:
```bash
rails railspress:install:migrations
rails db:migrate
```

JavaScript upgrade notes:

- New installs auto-import RailsPress in the admin layout (`<script type="module">import "railspress"</script>`), so Lexxy loads automatically in admin.
- Keep/add `import "railspress"` in your host `app/javascript/application.js` when using host-page features like inline CMS editing.
- If you previously pinned `lexxy` manually in host `config/importmap.rb`, you can remove that pin (engine importmap now provides it).
- If you override RailsPress admin layout in your app, add back the admin import line manually.

### API support upgrade notes

If you are upgrading to a version that includes API support:

1. Copy and run migrations:

```bash
rails railspress:install:migrations
rails db:migrate
```

2. Configure Active Record Encryption keys in your host app. Run `bin/rails db:encryption:init` to generate the standard credentials snippet; RailsPress never writes it for you.
3. Enable API in your RailsPress initializer (`config.enable_api`).
4. Open `/railspress/admin/api_keys` (Agents & API) and create:
   - an **Agent Key** (bootstrap, one-time exchange), or
   - an **API Key** (direct bearer token).

See [Blocks & Inline Editing](INLINE_EDITING.md) and [Configuring](CONFIGURING.md) for full details.

### Upgrading to 0.1.x

Initial release. Run full install:

```bash
rails generate railspress:install
rails db:migrate
```

## CI/CD Considerations

### Automated Upgrades

In CI, ensure migrations run before tests:

```yaml
# .github/workflows/test.yml
- name: Setup database
  run: |
    rails railspress:install:migrations
    rails db:create db:migrate
```

### Production Deployments

For zero-downtime deploys, run migrations before deploying new code if they're additive (new tables, new columns with defaults).

For destructive migrations (removing columns), deploy code first, then migrate.

```bash
# Typical deploy sequence
git pull origin main
bundle install
rails railspress:install:migrations
rails db:migrate
rails assets:precompile
# restart app
```

## Getting Help

- Check [CONFIGURING.md](CONFIGURING.md) for configuration options
- Check [IMPORT_EXPORT.md](IMPORT_EXPORT.md) for import/export features
- Review engine source: `bundle show railspress`
