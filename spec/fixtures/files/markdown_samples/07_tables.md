# Tables

## Basic Table

| Name | Type | Default |
|------|------|---------|
| title | string | nil |
| slug | string | auto-generated |
| status | enum | draft |
| published_at | datetime | nil |

## Alignment

| Left-aligned | Center-aligned | Right-aligned |
|:-------------|:--------------:|--------------:|
| Left | Center | Right |
| Content | Content | Content |
| More | More | More |

## Wide Table

| Feature | Blog | CMS | Inline Editing | Description |
|---------|:----:|:---:|:--------------:|-------------|
| Posts | Yes | - | - | Create and manage blog posts |
| Categories | Yes | - | - | Organize posts by category |
| Tags | Yes | - | - | Tag posts with keywords |
| Content Groups | - | Yes | - | Group related content elements |
| Content Elements | - | Yes | - | Manage text and image content |
| Right-click Edit | - | - | Yes | Edit CMS content inline on public pages |
| Import/Export | - | Yes | - | Bulk transfer CMS content as ZIP |

## Table with Formatting

| Method | Returns | Example |
|--------|---------|---------|
| `cms_value` | `String` or `nil` | `cms_value("Homepage", "Hero H1")` |
| `cms_element` | `String` (or yields block) | `cms_element("Homepage", "Hero H1")` |
| `CMS.find` | `CMSQuery` | `Railspress::CMS.find("Homepage")` |
| `.load` | `CMSQuery` | `.load("Hero H1")` |
| `.value` | `String` or `nil` | `.value` |

## Single-Column Table

| Configuration Options |
|-----------------------|
| `enable_authors` |
| `enable_post_images` |
| `enable_focal_points` |
| `enable_cms` |

## Minimal Table

| a | b |
|---|---|
| 1 | 2 |
