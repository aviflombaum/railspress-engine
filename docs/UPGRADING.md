# Upgrading RailsPress

This guide covers upgrading the RailsPress engine between versions.

## Quick Upgrade

```bash
# 1. Update the gem
bundle update railspress-engine

# 2. Copy new migrations
rails railspress:install:migrations

# 3. Run migrations
rails db:migrate

# 4. Restart your server
```

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

Add `import "railspress"` to your `app/javascript/application.js` if you haven't already (required for inline editing Stimulus controllers).

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
