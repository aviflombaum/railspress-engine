# Changelog

All notable changes to RailsPress will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Content Element CMS**: Structured content management with groups and elements. Text and image content types with a chainable Ruby API (`Railspress::CMS.find("Group").load("Element").value`) and view helpers (`cms_value`, `cms_element`).
- **Inline CMS Editing**: Right-click any `cms_element` in the frontend to edit in place. Lazy-loads form via Turbo Frame, saves with dual Turbo Streams. Configure with `Railspress.configure { |c| c.inline_editing_check = ->(ctx) { ... } }`.
- **Image Content Elements**: Content elements can be text or image type. Image elements support upload via dropzone, `image_hint` field for admin guidance on recommended dimensions, and focal point cropping.
- **Required Content Elements**: Boolean `required` flag on content elements prevents accidental deletion of elements your application code depends on.
- **Auto-Versioning**: Content element edits automatically create `ContentElementVersion` records storing the previous value, providing a full audit trail.
- **CMS Content Export/Import**: Export content groups and elements (including images) as ZIP files. Import on another environment to sync CMS content across staging/production.
- **Content Element Thumbnails**: Image content elements show a thumbnail preview in the admin index and content group show pages.
- **Soft Deletion**: Content groups use `SoftDeletable` concern for non-destructive deletion.

## [0.1.2] - 2026-02-11

### Added

- **Focal Point System**: Set focal points on header images to control how they crop across different aspect ratios. Includes per-context overrides for hero banners, cards, and thumbnails.
- **Markdown Mode**: Toggle between rich text and markdown editing in the post form. Bidirectional conversion between HTML and markdown.
- **Custom Index Columns**: Configure which columns appear in entity index tables using `RAILSPRESS_INDEX_COLUMNS` constant or `railspress_index_columns` method.
- **Polymorphic Tagging**: New `Railspress::Taggable` concern allows any entity to have tags. Shared tag pool across all taggable models.
- **Collapsible Sidebar**: Admin sidebar can be collapsed/expanded. State persists via localStorage.
- **`blog_path` Configuration**: Configure the public blog URL path for "View" button links in admin.
- **Dropzone Uploads**: Drag-and-drop file uploads with progress indicators for imports and images.
- **Reading Time**: Auto-calculated reading time on posts based on configurable words-per-minute.
- **Entity System**: Manage any ActiveRecord model through the admin interface with the `Railspress::Entity` concern.
- **Import/Export**: Bulk import and export posts with markdown and YAML frontmatter.

### Changed

- **Polymorphic Tagging**: Tags now use a polymorphic `railspress_taggings` table instead of the previous `railspress_post_tags` join table. This enables tagging on any model, not just posts.
- **CSS Architecture**: Refactored admin CSS into component files (`buttons.css`, `cards.css`, `tables.css`, etc.) for better maintainability.
- **License**: Updated to O'Saasy License.

### Fixed

- Prevent crash when header image validation fails during post creation.
- Fix import type hidden field nesting under import params.

### Migration Notes

If upgrading from a version that used `railspress_post_tags`:

1. Run `rails railspress:install:migrations` to get the new taggings migration
2. Run `rails db:migrate` to create the new polymorphic table
3. Existing post-tag relationships will need to be migrated (see UPGRADING.md)
