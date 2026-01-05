# RailsPress Documentation

## Guides

- **[ENTITIES.md](ENTITIES.md)** - Manage any ActiveRecord model through the admin interface with the Entity system.
- **[BLOGGING.md](BLOGGING.md)** - Complete guide to building a blog frontend with RailsPress, including recent posts, categories, tags, search, RSS feeds, and SEO optimization.
- **[CONFIGURING.md](CONFIGURING.md)** - Configuration options for authors, header images, view overrides, and other features.
- **[IMPORT_EXPORT.md](IMPORT_EXPORT.md)** - Bulk import and export posts with markdown and YAML frontmatter.
- **[THEMING.md](THEMING.md)** - CSS variables and theming customization for the admin interface.
- **[ADMIN_HELPERS.md](ADMIN_HELPERS.md)** - Reference for admin view helper methods (forms, layouts, display).
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions.
- **[UPGRADING.md](UPGRADING.md)** - How to upgrade between versions and copy new migrations.

## Quick Links

- [Admin Interface](#admin-interface)
- [Models Reference](#models-reference)

---

## Admin Interface

Access the admin at `/railspress/admin`:

| Path | Description |
|------|-------------|
| `/railspress/admin` | Dashboard |
| `/railspress/admin/posts` | Manage posts |
| `/railspress/admin/categories` | Manage categories |
| `/railspress/admin/tags` | Manage tags |

---

## Models Reference

### Railspress::Post

| Attribute | Type | Description |
|-----------|------|-------------|
| `title` | string | Post title (required) |
| `slug` | string | URL-friendly identifier (auto-generated) |
| `content` | rich_text | Post body (Action Text) |
| `excerpt` | text | Optional post summary/teaser |
| `status` | enum | `draft` or `published` |
| `published_at` | datetime | When post was published |
| `reading_time` | integer | Estimated reading time in minutes (auto-calculated) |
| `meta_title` | string | SEO title override |
| `meta_description` | text | SEO description |
| `category_id` | integer | Optional category |
| `author_id` | integer | Author reference (when `enable_authors` is set) |
| `author_type` | string | Author class name (polymorphic) |

**Attachments (when `enable_post_images` is set):**
- `header_image` - ActiveStorage single attachment

**Associations:**
- `belongs_to :category` (optional)
- `has_many :tags` (through post_tags)
- `has_rich_text :content`
- `belongs_to :author, polymorphic: true` (when authors enabled)

**Scopes:**
- `published` - Posts with status "published" and a `published_at` date set
- `drafts` - Posts with status "draft"
- `ordered` - By `published_at` descending (published first, then created_at)
- `recent` - Last 10 posts (combines `ordered.limit(10)`)
- `by_author(author)` - Filter by author (when authors enabled)
- `by_category(category_or_id)` - Filter by category
- `by_status(status)` - Filter by status enum value
- `search(query)` - ILIKE search on title
- `sorted_by(column, direction)` - Multi-column sorting

```ruby
# Examples
Railspress::Post.published.ordered.limit(5)
Railspress::Post.by_category(@category).published
Railspress::Post.search("rails").published
Railspress::Post.sorted_by(:title, :asc)
```

**Instance Methods:**
- `tag_list` / `tag_list=` - Get/set tags as CSV string
- `reading_time_display` - Returns `reading_time` or calculates from content
- `calculate_reading_time` - Word count / `Railspress.words_per_minute`
- `author` / `author=` - Get/set polymorphic author (when authors enabled)
- `remove_header_image` / `remove_header_image=` - Virtual attribute for image removal

### Railspress::Category

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Category name (required, unique) |
| `slug` | string | URL-friendly identifier (auto-generated) |

**Associations:**
- `has_many :posts`

**Scopes:**
- `ordered` - Alphabetically by name

### Railspress::Tag

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Tag name (required, unique, lowercase) |
| `slug` | string | URL-friendly identifier (auto-generated) |

**Associations:**
- `has_many :posts` (through post_tags)

**Scopes:**
- `ordered` - Alphabetically by name

**Class Methods:**
- `from_csv(string)` - Parse CSV and find/create tags

---

## Route Helpers

RailsPress routes are namespaced under `railspress`. Use these helpers from your host application.

### Admin Routes

```ruby
# Dashboard
railspress.admin_root_path             # => "/blog/admin"

# Posts
railspress.admin_posts_path            # => "/blog/admin/posts"
railspress.new_admin_post_path         # => "/blog/admin/posts/new"
railspress.admin_post_path(post)       # => "/blog/admin/posts/123"
railspress.edit_admin_post_path(post)  # => "/blog/admin/posts/123/edit"

# Categories
railspress.admin_categories_path       # => "/blog/admin/categories"
railspress.admin_category_path(cat)    # => "/blog/admin/categories/123"

# Tags
railspress.admin_tags_path             # => "/blog/admin/tags"
railspress.admin_tag_path(tag)         # => "/blog/admin/tags/123"
```

### Entity Routes

```ruby
# List entities
railspress.admin_entity_index_path(entity_type: "projects")
# => "/blog/admin/entities/projects"

# Single entity
railspress.admin_entity_path(entity_type: "projects", id: 1)
# => "/blog/admin/entities/projects/1"

# New entity
railspress.admin_entity_new_path(entity_type: "projects")
# => "/blog/admin/entities/projects/new"

# Edit entity
railspress.admin_entity_edit_path(entity_type: "projects", id: 1)
# => "/blog/admin/entities/projects/1/edit"
```

### Import/Export Routes

```ruby
# Import
railspress.typed_admin_imports_path(type: "posts")
# => "/blog/admin/imports/posts"

# Export
railspress.typed_admin_exports_path(type: "posts")
# => "/blog/admin/exports/posts"
```

### Using in Views

From your host app views, reference RailsPress routes:

```erb
<%# Link to admin %>
<%= link_to "Manage Blog", railspress.admin_root_path %>

<%# Link to specific post in admin %>
<%= link_to "Edit", railspress.edit_admin_post_path(@post) %>
```

### Main App Routes from Engine Views

From within RailsPress views, use `main_app` to access your host app routes:

```erb
<%# From a RailsPress view, link back to host app %>
<%= link_to "Home", main_app.root_path %>
