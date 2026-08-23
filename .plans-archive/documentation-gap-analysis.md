---
title: "Documentation Gap Analysis and Improvement Plan"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Configuration, helpers, routes, entities, theming, operations, security, installation, and drift guards are documented."
---

# Documentation Gap Analysis & Improvement Plan

## Overview

Audit of RailsPress documentation to identify undocumented features and improve end-user documentation coverage.

## Current Documentation Structure

| File | Purpose | Status |
|------|---------|--------|
| `README.md` | Quick start, installation | Minimal |
| `docs/README.md` | Hub with links + model reference | Partial |
| `docs/ENTITIES.md` | Entity system (custom models) | Complete |
| `docs/BLOGGING.md` | Frontend blog building | Complete |
| `docs/CONFIGURING.md` | Configuration options | Partial |
| `docs/IMPORT_EXPORT.md` | Bulk operations | Complete |
| `docs/UPGRADING.md` | Version upgrades | Complete |

---

## Priority 1: High Impact Gaps

### 1.1 Expand README.md with Feature Overview

**Current state:** 72 lines, minimal feature list, no Entity system mention.

**Missing:**
- Entity system mention (major feature)
- Link to docs/ folder
- Generator commands
- Quick customization examples
- Requirements for Lexxy editor

**Action:**
```markdown
## Additional Features

- **Entity System** - Manage any ActiveRecord model through admin ([docs](docs/ENTITIES.md))
- **Import/Export** - Bulk markdown operations ([docs](docs/IMPORT_EXPORT.md))
- **Theming** - CSS variable customization

## Generators

rails generate railspress:install    # Full setup
rails generate railspress:entity Project title:string  # Add custom entity
```

---

### 1.2 Complete Post Model Reference (docs/README.md)

**Missing attributes:**
- `excerpt` - Text field for post summary
- `reading_time` - Integer, auto-calculated minutes
- `author_id` - When authors enabled
- `header_image` - ActiveStorage attachment when enabled
- `remove_header_image` - Virtual attribute for removal

**Missing scopes:**
- `by_author(user)` - Filter by author
- `search(query)` - ILIKE title search
- `by_category(id)` - Filter by category
- `by_status(status)` - Filter by status enum
- `sorted_by(column, direction)` - Multi-column sort

**Missing methods:**
- `reading_time_display` - Returns reading_time or calculates it
- `calculate_reading_time` - Word count / WPM
- `author` / `author=` - Polymorphic author getter/setter

---

### 1.3 Add Configuration Options (docs/CONFIGURING.md)

**Missing options:**

```ruby
Railspress.configure do |config|
  # Reading time calculation (undocumented)
  config.words_per_minute = 200   # Default: 200

  # Alternative to current_author_method (undocumented)
  config.current_author_proc = -> { Current.user }
end

# Undocumented accessor
Railspress.words_per_minute  # => 200
```

---

### 1.4 Document ApplicationHelper Methods

**Missing from all docs.** Frontend helpers for blog views:

```ruby
# Reading time display
rp_reading_time(post)                      # => "5 min"
rp_reading_time(post, format: :long)       # => "5 minute read"

# Featured image URL with variant
rp_featured_image_url(post)
rp_featured_image_url(post, variant: { resize_to_limit: [1200, 630] })
```

**Where to document:** Add section to `docs/BLOGGING.md` under "Helpers"

---

## Priority 2: Medium Impact Gaps

### 2.1 Route Helpers Reference

**Undocumented.** Host app access to engine routes:

```ruby
# From host app controllers/views
railspress.admin_root_path           # => "/blog/admin"
railspress.admin_posts_path          # => "/blog/admin/posts"
railspress.admin_post_path(post)     # => "/blog/admin/posts/123"
railspress.admin_categories_path
railspress.admin_tags_path

# Entity routes
railspress.admin_entity_index_path(entity_type: "projects")
railspress.admin_entity_path(entity_type: "projects", id: 1)

# Import/Export
railspress.typed_admin_imports_path(type: "posts")
railspress.typed_admin_exports_path(type: "posts")
```

**Where to document:** Add section to `docs/README.md`

---

### 2.2 Entity System Pagination & Scopes

**Missing from docs/ENTITIES.md:**

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  # Pagination (built-in)
  PER_PAGE = 20                    # Override default

  # Built-in scopes from Entity
  Project.ordered                  # created_at DESC
  Project.recent                   # First 10, ordered
  Project.page(2)                  # Pagination helper
  Project.per_page_count           # Returns PER_PAGE or 20
end
```

---

### 2.3 AdminHelper Reference

**~600 lines of helper methods, completely undocumented for customizers.**

Create new file `docs/ADMIN_HELPERS.md`:

```markdown
# Admin Helper Reference

When overriding admin views, these helpers are available:

## Field Renderers

| Helper | Use Case |
|--------|----------|
| `rp_string_field(form, :title)` | Text input |
| `rp_text_field(form, :body, rows: 6)` | Textarea |
| `rp_rich_text_field(form, :content)` | Lexxy editor |
| `rp_boolean_field(form, :published)` | Checkbox |
| `rp_datetime_field(form, :published_at)` | Datetime picker |
| `rp_select_field(form, :status, choices: [...])` | Dropdown |
| `rp_attachment_field(form, :image, record: @post)` | File upload |

## Layout Helpers

| Helper | Output |
|--------|--------|
| `rp_page_header("Posts", actions: {...})` | Page title + buttons |
| `rp_card { content }` | Card wrapper |
| `rp_form_errors(record)` | Validation errors |
| `rp_sidebar_section("Options") { ... }` | Sidebar group |
| `rp_empty_state("No posts yet", link_text:, link_path:)` | Empty state |

## Display Helpers

| Helper | Output |
|--------|--------|
| `rp_status_badge("published", type: :success)` | Colored badge |
| `rp_boolean_badge(true)` | Yes/No badge |
| `rp_truncated_text(text, length: 50)` | Truncated with ellipsis |
```

---

### 2.4 CSS Theming Guide

**Undocumented.** Create new file `docs/THEMING.md`:

```markdown
# Theming RailsPress

## CSS Variables

Override in your application CSS:

```css
:root {
  /* Colors */
  --rp-primary: #2563eb;
  --rp-sidebar-bg: #1e293b;
  --rp-sidebar-text: #e2e8f0;

  /* Typography */
  --rp-font-display: "Inter", system-ui, sans-serif;
  --rp-font-body: "Inter", system-ui, sans-serif;

  /* Spacing */
  --rp-spacing-md: 1rem;
  --rp-radius: 0.375rem;
}
```

## Available Variables

See `app/assets/stylesheets/railspress/admin/variables.css` for full list.

## BEM Naming

All RailsPress classes use `rp-` prefix:
- `.rp-card` - Card container
- `.rp-btn` - Button base
- `.rp-form-group` - Form field wrapper
```

---

## Priority 3: Nice-to-Have

### 3.1 Taggable Concern for Reuse

**Undocumented.** Users can make their own models taggable:

```ruby
class Article < ApplicationRecord
  include Railspress::Taggable

  # Provides:
  # - has_many :taggings
  # - has_many :tags, through: :taggings
  # - tag_list / tag_list= virtual attributes
end
```

**Where to document:** Add section to `docs/ENTITIES.md` or new `docs/EXTENDING.md`

---

### 3.2 Background Job Configuration

**Mentioned in IMPORT_EXPORT.md but incomplete.**

Add:
```markdown
## Job Configuration

Import/Export use ActiveJob. Configure your adapter:

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq

# Queue name (default: "default")
# Jobs: Railspress::ImportPostsJob, Railspress::ExportPostsJob
```

---

### 3.3 View Override Patterns

**Undocumented.** Standard Rails engine pattern:

```markdown
## Customizing Views

Copy engine views to override:

```bash
# Copy specific view
mkdir -p app/views/railspress/admin/posts
cp $(bundle show railspress)/app/views/railspress/admin/posts/_form.html.erb \
   app/views/railspress/admin/posts/

# Your app's views take precedence
```

### Partials Available for Override

- `layouts/railspress/admin.html.erb` - Main layout
- `railspress/admin/shared/_sidebar.html.erb` - Navigation
- `railspress/admin/shared/_flash.html.erb` - Flash messages
- `railspress/admin/entities/_form.html.erb` - Entity forms
```

---

## Implementation Plan

### Phase 1: Quick Wins (1 hour)

- [ ] Update `docs/CONFIGURING.md` with `words_per_minute` and `current_author_proc`
- [ ] Add `rp_reading_time` and `rp_featured_image_url` to `docs/BLOGGING.md`
- [ ] Expand Post model reference in `docs/README.md`

### Phase 2: Route & Helper Docs (2 hours)

- [ ] Add route helpers section to `docs/README.md`
- [ ] Add Entity pagination/scopes section to `docs/ENTITIES.md`
- [ ] Create `docs/ADMIN_HELPERS.md` with helper reference

### Phase 3: Theming & Extension (2 hours)

- [ ] Create `docs/THEMING.md` with CSS variables guide
- [ ] Add Taggable concern section
- [ ] Add view override patterns
- [ ] Update main README.md with full feature list

### Phase 4: Polish

- [ ] Add CHANGELOG.md with semantic versioning
- [ ] Add generator usage examples to README.md
- [ ] Cross-link all docs for discoverability

---

## Success Metrics

- All public configuration options documented
- All public helper methods documented
- All customization points explained with examples
- README.md serves as complete quick-start guide
- docs/ folder is comprehensive reference

---

## Critical Gaps Identified by Flow Analysis

### Security-Critical

1. **Admin is publicly accessible by default** - README must warn users to configure authentication BEFORE production
2. **No authentication examples in quick start** - Move auth setup from CONFIGURING.md to README.md

### Installation Blockers

3. **ActionText installation order unclear** - User must install ActionText BEFORE RailsPress
4. **Active Storage setup incomplete** - Header images fail silently without storage config
5. **Lexxy editor dependency undocumented** - Rich text editing breaks without Lexxy

### Entity System Gaps

6. **Field type auto-detection failures** - JSONB columns default to string, no guidance
7. **Entity associations undocumented** - Can entities belongs_to Category? Use Taggable?
8. **Entity pagination undocumented** - PER_PAGE constant, page(n) method not explained

### Integration Gaps

9. **Public post routes missing** - No `/blog/post-slug` routes, only admin routes
10. **ApplicationHelper availability unclear** - Must user include helper in host app?
11. **Route namespace collisions** - What if host app has `admin_posts_path`?

### DevOps Gaps

12. **Job queue configuration incomplete** - Which queue? How to configure?
13. **Partial import failure handling** - What happens when 50 of 100 posts fail?
14. **Export file cleanup strategy** - Do generated files get cleaned up?

---

## Revised Implementation Plan

### Phase 1: Critical Security & Installation (1 hour)

- [ ] Add security warning to README.md about authentication
- [ ] Move basic auth example from CONFIGURING.md to README quick start
- [ ] Add ActionText/ActiveStorage prerequisites checklist
- [ ] Document Lexxy dependency

### Phase 2: Quick Wins (1 hour)

- [ ] Update `docs/CONFIGURING.md` with `words_per_minute` and `current_author_proc`
- [ ] Add `rp_reading_time` and `rp_featured_image_url` to `docs/BLOGGING.md`
- [ ] Expand Post model reference in `docs/README.md`

### Phase 3: Route & Helper Docs (2 hours)

- [ ] Add route helpers section to `docs/README.md`
- [ ] Add Entity pagination/scopes section to `docs/ENTITIES.md`
- [ ] Create `docs/ADMIN_HELPERS.md` with helper reference
- [ ] Document ApplicationHelper inclusion pattern

### Phase 4: Theming & Extension (2 hours)

- [ ] Create `docs/THEMING.md` with CSS variables guide
- [ ] Add Taggable concern section (or document Post-only limitation)
- [ ] Add view override patterns
- [ ] Update main README.md with full feature list

### Phase 5: DevOps & Production (1 hour)

- [ ] Add job queue configuration to IMPORT_EXPORT.md
- [ ] Document partial failure handling
- [ ] Add export cleanup guidance

### Phase 6: Troubleshooting

- [ ] Create `docs/TROUBLESHOOTING.md` with common errors
- [ ] ActionText not installed errors
- [ ] Authentication not configured warnings
- [ ] Entity field type mismatch debugging

---

## Files to Create

| New File | Purpose |
|----------|---------|
| `docs/ADMIN_HELPERS.md` | Helper method reference |
| `docs/THEMING.md` | CSS customization guide |
| `docs/TROUBLESHOOTING.md` | Common errors and solutions |
| `CHANGELOG.md` | Version history |

## Files to Update

| File | Changes |
|------|---------|
| `README.md` | Add features, generators, docs links |
| `docs/README.md` | Expand Post model, add route helpers |
| `docs/CONFIGURING.md` | Add words_per_minute, current_author_proc |
| `docs/BLOGGING.md` | Add helper methods section |
| `docs/ENTITIES.md` | Add pagination/scopes, Taggable section |
| `docs/IMPORT_EXPORT.md` | Add job configuration |
