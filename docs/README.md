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
- **[api/README.md](api/README.md)** - Programmatic API: authentication, errors, and endpoint reference.
- **[image-focal-point-system.md](image-focal-point-system.md)** - Focal point image cropping for posts and content elements.
- **[THEMING.md](THEMING.md)** - CSS variables and theming customization for the admin interface.
- **[ADMIN_HELPERS.md](ADMIN_HELPERS.md)** - Reference for admin view helper methods (forms, layouts, display).
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions.
- **[UPGRADING.md](UPGRADING.md)** - How to upgrade between versions and copy new migrations.
- **[MAINTENANCE.md](MAINTENANCE.md)** - Doctor, upgrade, migration-copy, and legacy maintenance tasks.

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
| `/railspress/admin/content_groups` | Manage block groups |
| `/railspress/admin/content_elements` | Manage blocks (content elements) |
| `/railspress/admin/cms_transfer` | Block export/import |
| `/railspress/admin/api_keys` | Manage API and agent onboarding keys when Agents & API is enabled |

---

## Models Reference

### Railspress::Post

| Attribute | Type | Description |
|-----------|------|-------------|
| `title` | string | Post title (required) |
| `slug` | string | URL-friendly identifier (auto-generated) |
| `content` | rich_text | Post body (Action Text) |
| `status` | enum | `draft` or `published` |
| `published_at` | datetime | When post was published |
| `reading_time` | integer | Estimated reading time in minutes (auto-calculated) |
| `meta_title` | string | SEO title override |
| `meta_description` | text | SEO description |
| `category_id` | integer | Optional category |
| `author_id` | bigint | ID in the configured author class (when `enable_authors` is set) |

**Attachments (when `enable_post_images` is set):**
- `header_image` - ActiveStorage single attachment
- `gallery_images` - ActiveStorage multiple attachments

**Associations:**
- `belongs_to :category` (optional)
- `has_many :taggings, as: :taggable`
- `has_many :tags, through: :taggings`
- `has_rich_text :content`
- `author` is resolved from `author_id` through `config.author_class_name` when authors are enabled; Post does not store an `author_type` column

**Scopes:**
- `published` - Published-status posts whose `published_at` is in the past or present
- `drafts` - Posts with status "draft"
- `scheduled` - Published-status posts whose `published_at` is in the future
- `live` - Alias for the `published` scope
- `ordered` - By `created_at` descending
- `recent` - Last 10 posts by creation time (combines `ordered.limit(10)`)
- `by_author(author)` - Filter by author (when authors enabled)
- `by_category(category_id)` - Filter by category ID
- `by_status(status)` - Filter by status enum value
- `rp_search(query)` - RailsPress's case-insensitive substring search on title
- `rp_page(page_number)` - RailsPress's lightweight pagination
- `rp_per_page_count` - Resolved RailsPress page size (defaults to 20)
- `sorted_by(column, direction)` - Multi-column sorting

```ruby
# Examples
Railspress::Post.published.ordered.limit(5)
Railspress::Post.by_category(@category).published
Railspress::Post.rp_search("rails").published
Railspress::Post.published.rp_page(params[:page])
Railspress::Post.sorted_by(:title, :asc)
```

The `rp_*` query methods are dependency-free defaults used by the engine. Host applications can use
their own search and pagination APIs instead. The older `search`, `page`, and `per_page_count` names
remain as conditional compatibility methods until RailsPress 2.0 and should not be used in new code.

**Instance Methods:**
- `tag_list` / `tag_list=` - Get/set tags as CSV string
- `reading_time_display` - Returns `reading_time` or calculates from content
- `calculate_reading_time` - Word count / `Railspress.words_per_minute`
- `author` / `author=` - Resolve or assign an ID in the configured author class
- `scheduled?` / `live?` - Compare `published_at` with the current time
- `display_status` - Returns `scheduled` for future published-status posts, otherwise the stored status
- `remove_header_image` / `remove_header_image=` - Virtual attribute for image removal

### Railspress::Category

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Category name (required, unique) |
| `slug` | string | URL-friendly identifier (auto-generated) |
| `description` | text | Optional category description |

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
- `has_many :taggings`
- `has_many :posts, through: :taggings` for the `Railspress::Post` taggable type

**Scopes:**
- `ordered` - Alphabetically by name

**Class Methods:**
- `from_csv(string)` - Parse CSV and find/create tags

### Railspress::ContentGroup (Block Group)

A group of related blocks (e.g., "Homepage Hero", "Contact Info").

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Group name (required, unique) |
| `description` | text | Optional description |
| `author_id` | bigint | ID in the configured author class, when authors are enabled |
| `deleted_at` | datetime | Soft-deletion timestamp |

**Associations:**
- `has_many :content_elements`

**Computed methods:**
- `element_count` - Counts active (not soft-deleted) content elements
- `soft_delete` - Soft-deletes the group and its elements unless a required active element blocks deletion

### Railspress::ContentElement (Block)

An individual block — a piece of text or an image on your site.

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
| `author_id` | bigint | ID in the configured author class, when authors are enabled |
| `deleted_at` | datetime | Soft-deletion timestamp |

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
| `content_element_id` | integer | Parent element |
| `author_id` | bigint | ID in the configured author class, when authors are enabled |
| `text_content` | text | Text snapshot stored for this version |
| `version_number` | integer | Sequence number unique within the content element |

Versions are auto-created when text content changes. `changes_from_previous` is a computed hash that compares this snapshot with the preceding version; it is not a database column. `image_version` is an Active Storage attachment defined on the version model, although current automatic version creation records text changes only.

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

### Block Routes

```ruby
# Content Groups (Block Groups)
railspress.admin_content_groups_path              # => "/blog/admin/content_groups"
railspress.admin_content_group_path(group)        # => "/blog/admin/content_groups/123"

# Content Elements
railspress.admin_content_elements_path            # => "/blog/admin/content_elements"
railspress.admin_content_element_path(element)    # => "/blog/admin/content_elements/123"

# CMS Transfers (export/import)
railspress.admin_cms_transfer_path                # => "/blog/admin/cms_transfer"

# Agents & API key management
railspress.admin_api_keys_path                    # => "/blog/admin/api_keys"
railspress.new_admin_api_key_path                 # => "/blog/admin/api_keys/new"
railspress.new_admin_agent_bootstrap_key_path     # => "/blog/admin/agent_bootstrap_keys/new"
```

### Entity Routes

The names below are host-callable helpers on the `railspress` route proxy. Inside the generic entity controller/views, RailsPress also exposes convenience helpers such as `entity_index_path`, `entity_show_path`, `entity_new_path`, and `entity_edit_path`; those are controller-local helpers and are not methods on the host route proxy.

```ruby
# List entities
railspress.admin_entity_index_path(entity_type: "projects")
# => "/blog/admin/entities/projects"

# Single entity
railspress.admin_entity_path(entity_type: "projects", id: 1)
# => "/blog/admin/entities/projects/1"

# New entity
railspress.admin_new_entity_path(entity_type: "projects")
# => "/blog/admin/entities/projects/new"

# Edit entity
railspress.admin_edit_entity_path(entity_type: "projects", id: 1)
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
