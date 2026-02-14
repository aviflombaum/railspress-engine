# Import & Export

RailsPress provides two transfer systems:

1. **Post Import/Export** — Background-processed bulk content migration with YAML frontmatter support
2. **Block Transfer** — Synchronous export/import of content groups and elements (blocks) between environments

---

## CMS Content Transfer

Transfer CMS content (groups, elements, and images) between environments via ZIP files. Designed for promoting content created in development to production.

### Quick Reference

| Feature | Export | Import |
|---------|--------|--------|
| Route | `POST /admin/cms_transfer/export` | `POST /admin/cms_transfer/import` |
| Format | `.zip` (JSON manifest + images) | `.zip` (same format) |
| Processing | Synchronous (inline) | Synchronous (inline) |
| Scope | Active groups + elements only | Creates, updates, or restores |
| Images | Included in `images/` directory | Attached via Active Storage |

### Admin UI

Navigate to **CMS Transfer** in the admin sidebar. The page shows:

- **Export section** — Content summary (group/element/image counts), group table, and "Export All Content" button
- **Import section** — Drag-and-drop file upload area with file info display

After an import, a results panel shows badges for created, updated, restored, and error counts, with collapsible error details.

### ZIP Format

```
cms_content_20260207_143022.zip
├── content.json
└── images/
    ├── headers/
    │   └── hero-image.png
    └── footers/
        └── footer-logo.jpg
```

### JSON Manifest Schema

```json
{
  "version": 1,
  "exported_at": "2026-02-07T14:30:22-05:00",
  "source": "RailsPress CMS",
  "groups": [
    {
      "name": "Headers",
      "description": "Site header content elements",
      "elements": [
        {
          "name": "Homepage H1",
          "content_type": "text",
          "position": 1,
          "text_content": "Welcome to Our Site"
        },
        {
          "name": "Hero Image",
          "content_type": "image",
          "position": 2,
          "text_content": null,
          "image_path": "images/headers/hero-image.png"
        }
      ]
    }
  ]
}
```

Fields:

- `version` — Schema version (currently `1`), for forward compatibility
- `exported_at` — ISO 8601 timestamp
- `source` — Always `"RailsPress CMS"`
- `groups[].name` — Group name (used as match key on import)
- `groups[].elements[].name` — Element name (used as match key within group)
- `groups[].elements[].image_path` — Relative path to image in the ZIP (image elements only)
- `author_id` is intentionally excluded (meaningless across environments)

### Export

Exports all active (non-deleted) content groups and their active elements.

```ruby
# Programmatic usage
result = Railspress::ContentExportService.new.call
result.zip_data      # => binary ZIP data
result.filename      # => "cms_content_20260207_143022.zip"
result.group_count   # => 2
result.element_count # => 5
```

ZIP is generated in-memory using `Zip::OutputStream.write_buffer` — no temp files.

Image paths are sanitized: `images/{group-name}/{element-name}.{ext}` with non-alphanumeric characters replaced by hyphens.

### Import

Imports a previously exported ZIP. Content is matched by name:

- **Groups** — matched by `name`
- **Elements** — matched by `(content_group, name)` pair

Behavior for each record:

| State | Action |
|-------|--------|
| Not found | Create new |
| Found (active) | Update attributes |
| Found (soft-deleted) | Restore and update |

```ruby
# Programmatic usage
result = Railspress::ContentImportService.new(zip_file).call
result.created   # => 2
result.updated   # => 3
result.restored  # => 1
result.errors    # => ["Group 'X': Name can't be blank"]
result.success?  # => true (when errors is empty)
```

Key behaviors:

- **Idempotent** — Re-importing the same ZIP produces no duplicates or unnecessary changes
- **Auto-versioning** — Text content changes trigger the normal `after_save` versioning callback
- **Error collection** — Individual record errors are collected; processing continues for remaining items
- **CMS cache clearing** — `CmsHelper.cache` is cleared after import so templates reflect new content immediately

### Security

- **50 MB** maximum ZIP file size
- **500** maximum ZIP entries
- **Path traversal** — Entries containing `..` or starting with `/` are rejected
- **macOS artifacts** — `__MACOSX` and dotfile entries are skipped
- **Supported image types** — `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp` only
- Temp extraction directory cleaned up in `ensure` block

### Routes

```ruby
namespace :admin do
  resource :cms_transfer, only: [:show] do
    post :export, on: :member
    post :import, on: :member
  end
end
```

| Route Helper | Method | Path |
|--------------|--------|------|
| `admin_cms_transfer_path` | GET | `/admin/cms_transfer` |
| `export_admin_cms_transfer_path` | POST | `/admin/cms_transfer/export` |
| `import_admin_cms_transfer_path` | POST | `/admin/cms_transfer/import` |

### Database Prerequisite

A partial unique index ensures reliable name-based matching on import:

```ruby
add_index :railspress_content_elements,
          [:content_group_id, :name],
          unique: true,
          where: "deleted_at IS NULL",
          name: "idx_content_elements_unique_name_per_group"
```

This prevents duplicate active elements within a group while allowing soft-deleted records to coexist.

### File Reference

| File | Purpose |
|------|---------|
| `app/services/railspress/content_export_service.rb` | Builds ZIP with JSON manifest and images |
| `app/services/railspress/content_import_service.rb` | Processes uploaded ZIP, upserts by name |
| `app/controllers/railspress/admin/cms_transfers_controller.rb` | Show, export, and import actions |
| `app/views/railspress/admin/cms_transfers/show.html.erb` | Admin UI with drag-and-drop upload |
| `db/migrate/20260207000001_add_unique_index_to_content_elements.rb` | Partial unique index |

### Testing

```bash
# All CMS transfer tests (34 examples)
bundle exec rspec spec/services/railspress/content_export_service_spec.rb \
  spec/services/railspress/content_import_service_spec.rb \
  spec/requests/railspress/admin/cms_transfers_spec.rb
```

---

## Post Import & Export

Background-processed import and export for posts, enabling bulk content migration with YAML frontmatter support.

## Quick Reference

| Feature | Import | Export |
|---------|--------|--------|
| Route | `/admin/imports/posts` | `/admin/exports/posts` |
| Formats | `.md`, `.markdown`, `.txt`, `.zip` | `.zip` (markdown files) |
| Processing | Background job | Background job |
| Images | Attaches from zip or URL | Exports to `images/` folder |

## Import

### Supported File Types

- **Markdown** (`.md`, `.markdown`): Parsed with YAML frontmatter
- **Plain text** (`.txt`): Title derived from filename
- **Zip archives** (`.zip`): Processes all markdown/text files recursively

### Frontmatter Fields

```yaml
---
title: My Blog Post           # Required (or extracted from H1/filename)
slug: my-blog-post            # Optional, auto-generated if blank
status: published             # draft (default) or published
published_at: 2024-01-15      # Date, defaults to today
author: John Doe              # Case-insensitive match to existing author
category: Technology          # Case-insensitive match to existing category
tags: ruby, rails, tutorial   # Comma-separated or YAML array
header_image: images/hero.jpg # Relative path in zip or full URL
meta_title: SEO Title         # Optional SEO title
meta_description: SEO desc    # Optional SEO description
---
```

### Title Resolution

Title is resolved in order:

1. `title` field in frontmatter
2. First `# Heading` in content
3. Filename with dashes/underscores converted to spaces

### Header Images

Header images can be specified as:

**Relative path in zip:**
```yaml
header_image: images/hero.jpg
```

The processor looks for the file relative to the markdown file, then relative to the zip root.

**URL:**
```yaml
header_image: https://example.com/image.jpg
```

Downloads and attaches the image automatically.

### Zip Structure

```
my-posts.zip
├── post-one.md
├── post-two.md
├── images/
│   ├── post-one-hero.jpg
│   └── post-two-hero.png
└── drafts/
    └── work-in-progress.md
```

All markdown and text files are processed regardless of directory depth.

### Obsidian Compatibility

The import processor strips Obsidian-specific metadata:

- Hashtag lines (e.g., `#tag #another`)
- Task/checkbox lines (e.g., `- [x] Done`)
- Priority and date markers
- Project/category prefixes

### Processing Flow

1. User uploads files via drag-and-drop or file picker
2. Controller saves files to `tmp/uploads/import_{id}/`
3. `ImportPostsJob` enqueued with file paths
4. `PostImportProcessor` processes each file:
   - Extracts zip to `tmp/imports/{id}_{timestamp}/`
   - Parses frontmatter and content
   - Converts markdown to HTML via Redcarpet
   - Creates post with associations
   - Attaches header image
5. Cleans up temp files
6. Updates import status (completed/failed)

### Error Handling

- Individual file errors are recorded, processing continues
- Import marked "completed" if any posts succeed
- Import marked "failed" only if all posts fail
- Errors visible in "Recent Imports" table

## Export

### Output Format

Each post exports as a markdown file with YAML frontmatter:

```yaml
---
title: My Blog Post
slug: my-blog-post
status: published
published_at: "2024-01-15"
category: Technology
tags: ruby, rails, tutorial
author: John Doe
header_image: images/my-blog-post.png
meta_title: SEO Title
meta_description: SEO description
---

<p>Post content as HTML...</p>
```

### Content Format

Content is exported as HTML (the format stored by ActionText). Markdown parsers handle inline HTML, so the exported files remain valid markdown.

Note: Redcarpet converts Markdown to HTML on import but cannot reverse the conversion. Content that originated as markdown will export as the rendered HTML.

### Zip Structure

```
posts_export_20241223_143022.zip
├── post-one.md
├── post-two.md
├── another-post.md
└── images/
    ├── post-one.png
    └── another-post.jpg
```

### Processing Flow

1. User clicks "Export N posts" button
2. Controller creates Export record with status "pending"
3. `ExportPostsJob` enqueued
4. `PostExportProcessor` processes all posts:
   - Creates `tmp/exports/{id}_{timestamp}/` directory
   - Generates markdown file for each post
   - Copies header images to `images/` subfolder
   - Creates zip archive
   - Attaches zip to export record via ActiveStorage
5. Cleans up temp directory
6. Updates export status

### Downloading

Completed exports show a "Download" button in the Recent Exports table. The download streams directly from ActiveStorage via `send_data`.

## Database Schema

### Imports Table

```ruby
create_table :railspress_imports do |t|
  t.string :import_type, null: false
  t.string :filename
  t.string :content_type
  t.string :status, default: "pending"
  t.integer :total_count, default: 0
  t.integer :success_count, default: 0
  t.integer :error_count, default: 0
  t.text :error_messages
  t.bigint :user_id
  t.timestamps
end
```

### Exports Table

```ruby
create_table :railspress_exports do |t|
  t.string :export_type, null: false
  t.string :filename
  t.string :status, default: "pending"
  t.integer :total_count, default: 0
  t.integer :success_count, default: 0
  t.integer :error_count, default: 0
  t.text :error_messages
  t.bigint :user_id
  t.timestamps
end
```

Exports also use ActiveStorage attachment:

```ruby
has_one_attached :file
```

## Dependencies

- **rubyzip**: Zip file handling
- **redcarpet**: Markdown to HTML conversion (import only)

Both gems are included in the railspress gemspec.

## Job Queue Configuration

Import and export operations use ActiveJob for background processing. Configure your queue adapter for production use.

### Queue Adapter Setup

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq  # Or :solid_queue, :good_job, etc.
```

### Queue Names

RailsPress jobs use the default queue. To configure a specific queue:

```ruby
# config/initializers/railspress.rb
Rails.application.config.to_prepare do
  Railspress::ImportPostsJob.queue_as :imports
  Railspress::ExportPostsJob.queue_as :exports
end
```

### Job Classes

| Job | Purpose | Default Queue |
|-----|---------|---------------|
| `Railspress::ImportPostsJob` | Process uploaded import files | `default` |
| `Railspress::ExportPostsJob` | Generate export zip archives | `default` |

### Sidekiq Example

```yaml
# config/sidekiq.yml
:queues:
  - default
  - imports
  - exports
```

### Solid Queue Example (Rails 8+)

```ruby
# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 1
```

### Monitoring Jobs

Check job status via:

1. Your queue adapter's UI (Sidekiq Web, GoodJob dashboard, etc.)
2. The Recent Imports/Exports tables in the RailsPress admin
3. Rails logs for job completion/failure messages

### Failure Handling

When jobs fail:

- **Import failures**: Individual file errors are recorded in `error_messages`. Processing continues for remaining files. Import marked "failed" only if all files fail.
- **Export failures**: Export status set to "failed" with error message. Partial exports are cleaned up.

Retry behavior follows your queue adapter's configuration. RailsPress jobs are safe to retry.

### File Cleanup

Temporary files are cleaned up after processing:

| Location | Cleaned When |
|----------|--------------|
| `tmp/uploads/import_{id}/` | After import job completes |
| `tmp/imports/{id}_{timestamp}/` | After import job completes |
| `tmp/exports/{id}_{timestamp}/` | After export zip is attached to record |

Export zip files are stored via ActiveStorage and follow your storage configuration's lifecycle.

## Routes

```ruby
namespace :admin do
  resources :imports, only: [:create] do
    collection do
      get ":type", action: :show, as: :typed
    end
  end

  resources :exports, only: [:create] do
    collection do
      get ":type", action: :show, as: :typed
    end
    member do
      get :download
    end
  end
end
```

| Route Helper | Path |
|--------------|------|
| `typed_admin_imports_path(type: "posts")` | `/admin/imports/posts` |
| `admin_imports_path` | POST `/admin/imports` |
| `typed_admin_exports_path(type: "posts")` | `/admin/exports/posts` |
| `admin_exports_path` | POST `/admin/exports` |
| `download_admin_export_path(export)` | `/admin/exports/:id/download` |

## Configuration

Import/export respects these Railspress configuration options:

```ruby
Railspress.configure do |config|
  config.enable_post_images = true   # Include header images in import/export
  config.enable_authors = true         # Include author in frontmatter
  config.author_class = "User"         # Model for author lookup
  config.author_display_method = :name # Field to match/display author
end
```

## Extending

### Adding New Export Types

1. Add type to `Export::EXPORT_TYPES`
2. Create processor class (e.g., `PageExportProcessor`)
3. Update `ExportPostsJob` or create dedicated job
4. Add route and controller handling

### Custom Frontmatter Fields

Extend `PostImportProcessor#create_post` and `PostExportProcessor#build_frontmatter` to handle additional fields.
