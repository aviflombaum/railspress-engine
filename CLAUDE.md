# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RailsPress is a mountable Rails engine that provides blog and CMS functionality for Rails 8+ applications. Includes post management (categories, tags, rich text), a content element CMS with inline editing, image uploads with focal point cropping, and content export/import.

## Development Commands

```bash
# Install dependencies
bundle install

# Run tests (from engine root)
bundle exec rspec

# Run single test file
bundle exec rspec spec/models/railspress/post_spec.rb

# Run specific test
bundle exec rspec spec/models/railspress/post_spec.rb:15

# Lint code
bin/rubocop

# Lint with auto-fix
bin/rubocop -a

# Run migrations in dummy app
cd spec/dummy && bin/rails db:migrate && cd ../..

# Start dummy app server (for manual testing)
cd spec/dummy && bin/rails server && cd ../..

# Rails console with dummy app
cd spec/dummy && bin/rails console && cd ../..
```

## Architecture

### Engine Structure

This is a **mountable Rails engine** with isolated namespace `Railspress`. All models, controllers, and views are namespaced to avoid conflicts with host applications.

```
app/
├── controllers/railspress/
│   ├── admin/
│   │   ├── base_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── categories_controller.rb
│   │   ├── tags_controller.rb
│   │   ├── posts_controller.rb
│   │   ├── content_groups_controller.rb
│   │   ├── content_elements_controller.rb
│   │   └── cms_transfers_controller.rb
│   └── application_controller.rb
├── models/railspress/
│   ├── post.rb              # ActionText, belongs_to category, has_many tags
│   ├── category.rb
│   ├── tag.rb
│   ├── post_tag.rb
│   ├── content_group.rb     # Groups of CMS content elements
│   ├── content_element.rb   # Text or image CMS content (has_one_attached :image)
│   └── content_element_version.rb  # Auto-versioning audit trail
├── helpers/railspress/
│   ├── admin_helper.rb      # Admin view helpers
│   └── cms_helper.rb        # cms_value / cms_element view helpers
├── javascript/railspress/
│   └── controllers/         # Stimulus controllers (dropzone, focal-point, inline-editor)
└── views/railspress/
    └── admin/               # Admin views (layouts, dashboard, CRUD views)
```

### Key Model Relationships

- `Post` belongs_to `:category` (optional), has_many `:tags` through `:post_tags`
- `Post` uses ActionText (`has_rich_text :content`)
- `Tag.from_csv(string)` creates/finds tags from comma-separated input
- Posts have `draft`/`published` status enum, auto-set `published_at`
- `ContentGroup` has_many `:content_elements`, with `element_count` counter cache
- `ContentElement` belongs_to `:content_group`, enum `content_type: { text: 0, image: 1 }`
- `ContentElement` has `required` flag (prevents deletion), `image_hint` for admin guidance
- `ContentElement` auto-creates `ContentElementVersion` on updates (stores previous value)
- CMS API: `Railspress::CMS.find("Group").load("Element").value`
- View helpers: `cms_value("Group", "Element")` and `cms_element("Group", "Element")` (inline-editable)

### Routes

Engine routes are defined in `config/routes.rb` and mounted by the host app:

```ruby
# In host app's config/routes.rb
mount Railspress::Engine => "/cms", as: :railspress
```

Admin routes: `/cms/admin/posts`, `/cms/admin/categories`, `/cms/admin/tags`, `/cms/admin/content_groups`, `/cms/admin/content_elements`, `/cms/admin/cms_transfers`

### Testing

- Uses RSpec with fixtures (not factories)
- Fixtures in `spec/fixtures/railspress/`
- Dummy Rails app in `spec/dummy/` for integration testing
- Transactional fixtures enabled

### Styling

- Uses vanilla CSS with BEM-style naming (`rp-` prefix)
- UI prototypes in `.ai/railspress-ui/` directory
- Main stylesheet: `app/assets/stylesheets/railspress/application.css`
- No Tailwind or CSS framework dependencies
- **IMPORTANT**: See `.ai/ENTITY_VIEW_STYLE_GUIDE.md` for view styling patterns

### Creating New Entity Views

When adding new entity types, follow the patterns documented in `.ai/ENTITY_VIEW_STYLE_GUIDE.md`:

1. Use `AdminHelper` methods for consistent page structure
2. Choose simple vs complex form pattern based on entity complexity
3. Run styling consistency tests: `bundle exec rspec spec/system/railspress/admin/view_styling_spec.rb`

## Important Files

- `docs/` - User-facing documentation (README, guides for configuring, theming, inline editing, etc.)
- `.ai/ENTITY_VIEW_STYLE_GUIDE.md` - **View styling patterns and checklists**
- `lib/railspress/engine.rb` - Engine configuration and initializers
- `lib/railspress/configuration.rb` - All config options (authors, images, inline editing, etc.)
- `lib/railspress/cms.rb` - CMS chainable API for loading content elements
- `app/helpers/railspress/admin_helper.rb` - Helper methods for consistent admin views
- `app/helpers/railspress/cms_helper.rb` - `cms_value` and `cms_element` view helpers
- `app/models/concerns/railspress/has_focal_point.rb` - Focal point image concern
- `app/models/concerns/railspress/soft_deletable.rb` - Soft deletion for content groups

## Conventions

- Models use `validates` and `scope` class methods
- Slugs auto-generated from title via `before_validation` callback
- Tags accept CSV input via `tag_list=` virtual attribute
- Admin controllers inherit from `Railspress::Admin::BaseController`
- Views use engine layout: `railspress/admin`
