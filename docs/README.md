# RailsPress Reference

Detailed model attributes, route helpers, and API reference. For installation and overview, see the [main README](../README.md).

## Posts, Entities, and Blocks

RailsPress manages three kinds of content. Most sites need all three:

| | What it is | When to use it | Guide |
|--|-----------|----------------|-------|
| **Posts** | A blog — chronological content with categories and tags | Articles, news, announcements — content published serially over time | [Blogging](BLOGGING.md) |
| **Entities** | Structured content with custom schemas | Portfolios, case studies, resources — content with its own fields that isn't a blog post | [Entities](ENTITIES.md) |
| **Blocks** | The copy and images on your site itself | Homepage hero headline, footer tagline, "About Us" blurb — content that editors change without a developer | [Blocks & Inline Editing](INLINE_EDITING.md) |

**How to choose:**
- Is it published over time in a feed? → **Post**
- Does it have its own schema with multiple fields? → **Entity**
- Is it a piece of text or image baked into a page? → **Block**

Blocks are implemented as `ContentGroup` and `ContentElement` models internally.

## Guides

- **[BLOGGING.md](BLOGGING.md)** - Building a blog frontend: controllers, views, RSS feeds, SEO.
- **[ENTITIES.md](ENTITIES.md)** - Managing structured content (portfolios, case studies, etc.) through the admin.
- **[INLINE_EDITING.md](INLINE_EDITING.md)** - Blocks and inline editing: editable site copy and images.
- **[CONFIGURING.md](CONFIGURING.md)** - Configuration options for authors, header images, view overrides, and other features.
- **[IMPORT_EXPORT.md](IMPORT_EXPORT.md)** - Bulk import/export for posts (markdown) and CMS content (ZIP).
- **[image-focal-point-system.md](image-focal-point-system.md)** - Focal point image cropping for posts and content elements.
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
| `/railspress/admin/content_groups` | Manage CMS content groups |
| `/railspress/admin/content_elements` | Manage CMS content elements |
| `/railspress/admin/cms_transfers` | CMS content export/import |

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

### Railspress::ContentGroup

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Group name (required, unique) |
| `description` | text | Optional description |
| `element_count` | integer | Counter cache of elements |

**Associations:**
- `has_many :content_elements`

### Railspress::ContentElement

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Element name (required, unique within group) |
| `content_type` | enum | `text` or `image` (locked after creation) |
| `text_content` | text | Value for text elements |
| `image` | attachment | ActiveStorage image for image elements |
| `image_hint` | string | Guidance text for admins (e.g., recommended dimensions) |
| `position` | integer | Sort order within group |
| `required` | boolean | Required elements cannot be deleted |
| `content_group_id` | integer | Parent group |

**Associations:**
- `belongs_to :content_group`
- `has_many :content_element_versions`
- `has_one_attached :image`

**CMS API:**
```ruby
# Chainable lookup
Railspress::CMS.find("Hero Section").load("headline").value

# View helpers
cms_value("Hero Section", "headline")       # Returns raw value
cms_element("Hero Section", "headline")     # Returns value with inline editing wrapper
```

### Railspress::ContentElementVersion

| Attribute | Type | Description |
|-----------|------|-------------|
| `changes_from_previous` | text | Previous content before the edit |
| `author_id` | bigint | Who made the change |
| `content_element_id` | integer | Parent element |

Auto-created on each content element update, storing the previous value for audit history.

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

### CMS Routes

```ruby
# Content Groups
railspress.admin_content_groups_path              # => "/blog/admin/content_groups"
railspress.admin_content_group_path(group)        # => "/blog/admin/content_groups/123"

# Content Elements
railspress.admin_content_elements_path            # => "/blog/admin/content_elements"
railspress.admin_content_element_path(element)    # => "/blog/admin/content_elements/123"

# CMS Transfers (export/import)
railspress.admin_cms_transfer_path                # => "/blog/admin/cms_transfers"
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
