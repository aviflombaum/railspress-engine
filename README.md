<p align="center">
  <strong>RailsPress</strong><br>
  A mountable blog + CMS engine for Rails 8
</p>

<p align="center">
  <a href="https://rubygems.org/gems/railspress-engine"><img src="https://img.shields.io/gem/v/railspress-engine.svg?style=flat" alt="Gem Version"></a>
  <img src="https://img.shields.io/badge/Rails-8.1%2B-red.svg?style=flat" alt="Rails 8.1+">
  <img src="https://img.shields.io/badge/Ruby-3.3%2B-red.svg?style=flat" alt="Ruby 3.3+">
  <a href="https://osaasy.dev/"><img src="https://img.shields.io/badge/License-O'Saasy-blue.svg?style=flat" alt="License"></a>
</p>

---

RailsPress is a mountable Rails engine that gives your app a complete content management system — namespaced and isolated so it stays out of your way.

You can read more at [Railspress.org](https://railspress.org).

It manages three kinds of content:

## Posts, Entities, and Blocks

### Posts

Your blog. Chronological content published over time — articles, news, announcements. Categories, tags, draft/published workflow.

- Rich text editing with [Lexxy](https://github.com/aviflombaum/lexxy) + markdown mode toggle
- Categories, tags, draft/published workflow
- SEO metadata (meta title, meta description)
- Reading time auto-calculation
- Header images with focal point cropping
- Import/export (markdown + YAML frontmatter)

### Entities

Your pages of structured content. A portfolio with projects, a collection of case studies, a resources page with links — anything with its own schema that isn't a blog post.

You define a regular ActiveRecord model, include `Railspress::Entity`, and RailsPress gives it a full admin interface with CRUD, search, pagination, image uploads, and tagging — no scaffolding or custom views required.

- Define fields with `railspress_fields` DSL or let RailsPress auto-detect from your schema
- Supports string, text, rich text, boolean, datetime, attachments, array fields, and more
- Focal point image cropping for any attachment
- Polymorphic tagging
- Custom index columns, searchable fields, scopes
- Generator: `rails generate railspress:entity Project title:string description:text`

### Blocks

The copy and images on your site itself. Your homepage hero headline, an "About Us" blurb, a call-to-action, a footer tagline — the content that normally lives hardcoded in templates and requires a developer to change.

Blocks are organized into **groups** (e.g., "Homepage Hero", "Contact Info") and each block is either text or an image. You reference them in your views and they become editable in the admin — or inline, right on the page.

- Chainable Ruby API: `Railspress::CMS.find("Hero").load("headline").value`
- View helpers: `cms_value("Hero", "headline")` and `cms_element("Hero", "headline")`
- Inline editing — right-click any `cms_element` in the frontend to edit in place
- Auto-versioning with full audit trail
- Required blocks that can't be accidentally deleted
- Image blocks with upload, hints, and focal points
- Export/import block groups as ZIP

### Why all three?

Most content doesn't fit neatly into "blog posts." A portfolio piece isn't a post. A homepage headline isn't a post. RailsPress gives you the right tool for each kind of content instead of forcing everything through one model.

## Features

**Admin Interface**
- Dashboard with content stats and recent activity
- Full CRUD for posts, categories, tags, block groups, blocks, and entities
- Drag-and-drop image uploads with progress
- Collapsible sidebar, responsive design
- Vanilla CSS with BEM naming (`rp-` prefix) — no framework dependencies

**Developer Experience**
- Focal point image concern for any model: `focal_point_image :cover_photo`
- CSS variable theming
- Generators for installation and custom entities

## Requirements

- Rails 8.1+
- Ruby 3.3+
- ActionText
- Active Storage

## Installation

Ensure ActionText and Active Storage are installed:

```bash
rails action_text:install
rails active_storage:install
```

Add to your Gemfile:

```ruby
gem "railspress-engine"
```

Run the install generator:

```bash
bundle install
rails generate railspress:install
rails db:migrate
```

Mount the engine (the install generator does this automatically):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Railspress::Engine => "/railspress"
end
```

## Authentication

The admin interface is publicly accessible by default. Add authentication before deploying:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, if: :railspress_admin?

  private

  def railspress_admin?
    request.path.start_with?("/railspress/admin")
  end
end
```

See [CONFIGURING.md](docs/CONFIGURING.md) for more authentication patterns including Devise integration.

## Quick Start

Access the admin at `/railspress/admin`. From there you can manage posts, entities, and blocks.

### Posts

Create posts with rich text, categories, tags, and header images. Build your own frontend controllers and views — see the [Blogging guide](docs/BLOGGING.md).

### Entities

Generate a model and register it:

```bash
rails generate railspress:entity Project title:string client:string description:text
```

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_config do |c|
    c.admin_title = "Projects"
    c.searchable_columns = [:title, :client]
  end
end
```

It now has a full admin interface at `/railspress/admin/entities/projects`. See the [Entity System guide](docs/ENTITIES.md).

### Blocks

Set up inline editing for admins:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.inline_editing_check = ->(ctx) { ctx.current_user&.admin? }
end
```

Reference blocks in your views:

```erb
<%# Raw value (no editing wrapper) %>
<h1><%= cms_value("Homepage", "headline") %></h1>

<%# With inline editing (admins can right-click to edit in place) %>
<h1><%= cms_element("Homepage", "headline") %></h1>

<p><%= cms_element("Homepage", "subheadline") %></p>
<%= image_tag cms_value("Homepage", "hero_image"), alt: "Hero" %>
```

Create the "Homepage" group and its blocks in the admin at `/railspress/admin/content_groups`. See the [Inline Editing guide](docs/INLINE_EDITING.md).

## Generators

```bash
rails generate railspress:install                    # Full setup
rails generate railspress:entity Project title:string # Add a managed entity
```

## Documentation

**Posts, Entities, and Blocks:**

| Guide | Description |
|-------|-------------|
| [Building a Blog](docs/BLOGGING.md) | Frontend views, RSS, SEO for posts |
| [Entity System](docs/ENTITIES.md) | Structured content pages (portfolios, case studies, etc.) |
| [Blocks & Inline Editing](docs/INLINE_EDITING.md) | Editable site copy and images |

**Everything else:**

| Guide | Description |
|-------|-------------|
| [Reference](docs/README.md) | Models, routes, and API reference |
| [Configuring](docs/CONFIGURING.md) | Authors, images, inline editing, and all options |
| [Image Focal Points](docs/image-focal-point-system.md) | Smart cropping with focal points |
| [Import/Export](docs/IMPORT_EXPORT.md) | Bulk operations for posts and CMS content |
| [Theming](docs/THEMING.md) | CSS variable customization |
| [Admin Helpers](docs/ADMIN_HELPERS.md) | View helper reference |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues |
| [Upgrading](docs/UPGRADING.md) | Version upgrades and migrations |
| [Changelog](CHANGELOG.md) | Version history |

## Development

```bash
bundle install
cd spec/dummy && bundle exec rails db:migrate && cd ../..
bundle exec rspec
```

## License

Available as open source under the terms of the [O'Saasy License](https://osaasy.dev/).

## Trademarks

The Rails trademarks are the intellectual property of David Heinemeier Hansson, and exclusively licensed to the Rails Foundation. Uses of "Rails" and "Ruby on Rails" in this project are for identification purposes only and do not imply an endorsement by or affiliation with Rails, the trademark owner, or the Rails Foundation.
