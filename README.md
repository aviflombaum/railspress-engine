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

RailsPress is a mountable Rails engine that gives your app a complete blog and content management system. Posts with rich text editing, categories, tags, a structured CMS for managing content elements, image uploads with focal point cropping, inline editing, and an admin interface — all namespaced and isolated so it stays out of your way.

## Features

**Blog**
- Rich text editing with [Lexxy](https://github.com/aviflombaum/lexxy) + markdown mode toggle
- Categories, tags, draft/published workflow
- SEO metadata (meta title, meta description)
- Reading time auto-calculation
- Header images with focal point cropping

**Content Element CMS**
- Structured content groups and elements (text or image)
- Chainable Ruby API: `Railspress::CMS.find("Hero").load("headline").value`
- View helpers: `cms_value` and `cms_element`
- Inline editing — right-click any `cms_element` in the frontend to edit in place
- Auto-versioning with full audit trail
- Required elements that can't be accidentally deleted
- Image elements with upload, hints, and focal points

**Admin Interface**
- Dashboard with content stats and recent activity
- Full CRUD for posts, categories, tags, content groups, and content elements
- Drag-and-drop image uploads with progress
- CMS content export/import (ZIP)
- Post import/export (markdown + YAML frontmatter)
- Collapsible sidebar, responsive design
- Vanilla CSS with BEM naming (`rp-` prefix) — no framework dependencies

**Developer Experience**
- Entity system — manage any ActiveRecord model through admin with `include Railspress::Entity`
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

Access the admin at `/railspress/admin`. From there:

- Create posts with rich text, categories, and tags
- Set up content groups and elements for structured CMS content
- Upload images and set focal points for smart cropping
- Export/import content for backup or migration

### Using CMS Content in Views

```ruby
# In your initializer
Railspress.configure do |config|
  config.inline_editing_check = ->(ctx) { ctx.current_user&.admin? }
end
```

```erb
<%# Simple value %>
<h1><%= cms_value("Homepage", "headline") %></h1>

<%# With inline editing (wraps in editable span for admins) %>
<h1><%= cms_element("Homepage", "headline") %></h1>
```

### Using the Entity System

```bash
rails generate railspress:entity Project title:string description:text
```

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_config do |c|
    c.admin_title = "Projects"
    c.searchable_columns = [:title]
  end
end
```

## Generators

```bash
rails generate railspress:install                    # Full setup
rails generate railspress:entity Project title:string # Add a managed entity
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Reference](docs/README.md) | Models, routes, and API reference |
| [Configuring](docs/CONFIGURING.md) | Authors, images, inline editing, and all options |
| [Building a Blog](docs/BLOGGING.md) | Frontend controllers, views, RSS, SEO |
| [Entity System](docs/ENTITIES.md) | Manage custom models through admin |
| [Inline Editing](docs/INLINE_EDITING.md) | Right-click inline CMS editing |
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
