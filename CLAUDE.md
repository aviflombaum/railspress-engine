# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RailsPress is a mountable Rails engine that provides blog functionality with categories, tags, and rich text editing. It's designed as a drop-in CMS solution for Rails 8+ applications.

**Current Status**: MVP Sprint 3 complete (Post CRUD with rich text). Sprint 4 (Testing + Polish) is next.

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
│   ├── admin/              # Admin namespace controllers
│   │   ├── base_controller.rb      # Base for all admin controllers
│   │   ├── dashboard_controller.rb
│   │   ├── categories_controller.rb
│   │   ├── tags_controller.rb
│   │   └── posts_controller.rb
│   └── application_controller.rb
├── models/railspress/
│   ├── category.rb
│   ├── tag.rb
│   ├── post.rb             # Has rich text (ActionText), belongs_to category, has_many tags
│   └── post_tag.rb         # Join table for post-tag many-to-many
└── views/railspress/
    └── admin/              # Admin views (layouts, dashboard, CRUD views)
```

### Key Model Relationships

- `Post` belongs_to `:category` (optional), has_many `:tags` through `:post_tags`
- `Post` uses ActionText (`has_rich_text :content`)
- `Tag.from_csv(string)` creates/finds tags from comma-separated input
- Posts have `draft`/`published` status enum, auto-set `published_at`

### Routes

Engine routes are defined in `config/routes.rb` and mounted by the host app:

```ruby
# In host app's config/routes.rb
mount Railspress::Engine => "/cms", as: :railspress
```

Admin routes: `/cms/admin/posts`, `/cms/admin/categories`, `/cms/admin/tags`

### Testing

- Uses RSpec with fixtures (not factories)
- Fixtures in `spec/fixtures/railspress/`
- Dummy Rails app in `spec/dummy/` for integration testing
- Transactional fixtures enabled

### Styling

- Uses vanilla CSS with BEM-style naming (`rp-` prefix)
- UI prototypes in `.ai/railspress-ui/` directory
- Main stylesheet: `app/assets/stylesheets/railspress/admin.css`
- No Tailwind or CSS framework dependencies
- **IMPORTANT**: See `.ai/ENTITY_VIEW_STYLE_GUIDE.md` for view styling patterns

### Creating New Entity Views

When adding new entity types, follow the patterns documented in `.ai/ENTITY_VIEW_STYLE_GUIDE.md`:

1. Use `AdminHelper` methods for consistent page structure
2. Choose simple vs complex form pattern based on entity complexity
3. Run styling consistency tests: `bundle exec rspec spec/system/railspress/admin/view_styling_spec.rb`

## Important Files

- `.ai/sprints/OVERVIEW.md` - Sprint planning and architecture decisions
- `.ai/PLAN.md` - Full extraction plan with future features
- `.ai/railspress-ui/` - HTML/CSS prototypes for admin interface
- `.ai/ENTITY_VIEW_STYLE_GUIDE.md` - **View styling patterns and checklists**
- `lib/railspress/engine.rb` - Engine configuration and initializers
- `app/helpers/railspress/admin_helper.rb` - Helper methods for consistent admin views

## Conventions

- Models use `validates` and `scope` class methods
- Slugs auto-generated from title via `before_validation` callback
- Tags accept CSV input via `tag_list=` virtual attribute
- Admin controllers inherit from `Railspress::Admin::BaseController`
- Views use engine layout: `railspress/admin`
