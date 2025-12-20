# RailsPress Documentation

## Guides

- **[BLOGGING.md](BLOGGING.md)** - Complete guide to building a blog frontend with RailsPress, including recent posts, categories, tags, search, RSS feeds, and SEO optimization.

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
| `status` | enum | `draft` or `published` |
| `published_at` | datetime | When post was published |
| `meta_title` | string | SEO title override |
| `meta_description` | text | SEO description |
| `category_id` | integer | Optional category |

**Associations:**
- `belongs_to :category` (optional)
- `has_many :tags` (through post_tags)
- `has_rich_text :content`

**Scopes:**
- `published` - Posts with status "published" and a `published_at` date set
- `drafts` - Posts with status "draft"
- `ordered` - By created_at descending
- `recent` - Last 10 posts (ordered)

**Methods:**
- `tag_list` / `tag_list=` - Get/set tags as CSV string

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
