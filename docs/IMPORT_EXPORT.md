# Import & Export

RailsPress provides background-processed import and export for posts, enabling bulk content migration with YAML frontmatter support.

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
  config.enable_header_images = true   # Include header images in import/export
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
