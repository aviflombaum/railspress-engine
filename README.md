<p align="center">
  <strong>RailsPress</strong><br>
  A mountable blog + CMS engine for Rails 8
</p>

<p align="center">
  <a href="https://rubygems.org/gems/railspress-engine"><img src="https://img.shields.io/gem/v/railspress-engine.svg?style=flat&bump=true" alt="Gem Version"></a>
  <img src="https://img.shields.io/badge/Rails-8.1.3.1%2B-red.svg?style=flat" alt="Rails 8.1.3.1+">
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

- Rich text editing with [Lexxy](https://github.com/basecamp/lexxy) + markdown mode toggle
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
- Generator: `bin/rails generate railspress:entity Project title:string description:text`

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
- Engine-managed browser assets with no runtime JavaScript or font CDN dependency

## Requirements

- Rails 8.1.3.1+
- Ruby 3.3+
- ActionText
- Active Storage

The optional Agents & API feature also requires all three Active Record Encryption credentials. RailsPress checks for them when `config.enable_api` is enabled, but never generates or writes them. Generate the standard Rails credentials snippet with:

```bash
bin/rails db:encryption:init
```

Store the generated `primary_key`, `deterministic_key`, and `key_derivation_salt` values in the host application's Rails credentials or deployment secret-management system.

RailsPress also depends on `stimulus-rails >= 1.2.2` and supplies a local `@hotwired/stimulus` importmap pin. Hosts do not need a CDN pin. A host importmap pin with the same package name loads after the engine map and therefore remains authoritative when an application intentionally manages its own Stimulus asset.

## Installation

Ensure ActionText and Active Storage are installed:

```bash
bin/rails action_text:install
bin/rails active_storage:install
```

### Image variants

RailsPress can generate resized image variants for post header images and image helpers. RailsPress includes a secure version of `image_processing`, but Active Storage still needs a processor gem and its native system library.

Choose one processor and add its gem to your application's `Gemfile`:

```ruby
# Recommended for Rails 8.1.3.1+ applications
gem "ruby-vips", "~> 2.2", ">= 2.2.1"

# Or use ImageMagick instead
# gem "mini_magick", "~> 5.0"
```

Install the matching system library in every environment where variants are generated: libvips `8.13+` for `ruby-vips`, or [ImageMagick](https://imagemagick.org/) for `mini_magick`. Rails and ruby-vips cannot safely block untrusted libvips operations on older libvips releases. If your app uses ImageMagick, select it explicitly:

```ruby
# config/application.rb
config.active_storage.variant_processor = :mini_magick
```

Use `:vips` instead if you need to select libvips explicitly. RailsPress header images can be displayed without variants; this setup is required when your application requests resizing or format conversion.

Add to your Gemfile:

```ruby
gem "railspress-engine"
```

Run the install generator:

```bash
bundle install
bin/rails generate railspress:install
bin/rails db:migrate
```

The generator copies the complete RailsPress migration history, plus Action Text and Active Storage migrations when they are missing; mounts the engine; adds the Active Storage importmap pin when the host uses importmap; and creates the initializer when absent. The generated initializer enables post images, post focal points, and CMS blocks for new installations while leaving authors, inline editing, entities, and Agents & API opt-in. RailsPress migrations are installed even when the feature that uses their tables is disabled. The generator does not run migrations or write encryption credentials. Existing files and registrations are skipped where possible.

The installer reports whether Active Record Encryption is already configured. It only prints the setup command when the credentials are missing; API-disabled applications can otherwise continue normally. Existing installations should follow the [upgrade guide](docs/UPGRADING.md) rather than treating a generator rerun as a complete upgrade.

Check the resolved installation at any time with the read-only doctor command:

```bash
bin/rails railspress:doctor
```

Doctor prints color-coded `PASS`, `WARN`, and `FAIL` findings in an interactive terminal, with a suggested action for every warning or failure. Warnings return status `0`; definite configuration or migration failures return status `1` as a normal report rather than a Rake exception. It checks that the RailsPress initializer exists and contains valid Ruby before boot, reports settings that raise during initializer evaluation, and detects RailsPress validation errors and deprecated settings after boot. It also verifies every shipped migration and warns importmap hosts about redundant Lexxy pins/imports without editing host files. See [Maintenance Commands](docs/MAINTENANCE.md#railspressdoctor) for the full output and error contract.

For upgrades, run `bundle update railspress-engine`, optionally preview with `DRY_RUN=1 bin/rails railspress:upgrade`, then run `bin/rails railspress:upgrade`. The upgrade task copies every missing RailsPress migration and runs all pending host migrations; production deployments should commit copied migrations and use the host's normal `db:migrate` release step.

Mount the engine (the install generator does this automatically):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Railspress::Engine => "/railspress"
end
```

### Enabling Agents & API

After Active Record Encryption is configured, enable the API in the host initializer:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_api
  config.admin_authentication_method = :require_admin!
  config.current_admin_method = :current_user
end
```

RailsPress then exposes bearer-authenticated endpoints under the engine mount, such as `/railspress/api/v1/prime`, and key management under `/railspress/admin/api_keys`.

Mount the engine normally, without a host authentication route constraint. RailsPress browser controllers inherit the host application's `ApplicationController`, so they can call host authentication methods and run inherited callbacks. RailsPress API controllers use a separate `ActionController::API` stack and authenticate bearer tokens themselves.

For example, if the host already defines `require_admin!` and `current_user`, the two settings above protect all `/railspress/admin/*` requests and identify the administrator responsible for API key changes. If an inherited `ApplicationController` callback already protects RailsPress, `admin_authentication_method` may be omitted.

Do not wrap the mount in a session-only route constraint:

```ruby
Rails.application.routes.draw do
  mount Railspress::Engine => "/railspress"
end
```

An outer session constraint runs before RailsPress and makes token-only API requests return `404`. See [API authentication](docs/api/authentication.md) for key creation and bootstrap exchange.

## Authentication

The admin interface is publicly accessible by default. RailsPress admin controllers inherit your host `ApplicationController`; configure the host authentication method RailsPress should invoke before every admin action:

```ruby
Railspress.configure do |config|
  config.admin_authentication_method = :require_admin!
  config.current_admin_method = :current_user
end
```

Both methods are defined by the host application. RailsPress does not assume Devise, Warden, or any particular session model. The API controller stack does not inherit these browser callbacks and always requires its own bearer token.

See [CONFIGURING.md](docs/CONFIGURING.md) for more authentication patterns including Devise integration.

## Import Security

RailsPress stores imported files inside engine-owned temporary directories.

ZIP image references cannot escape their extraction directory.

Remote header images accept public HTTP and HTTPS destinations. Private and redirected destinations are rejected.

Configure request and worker limits for additional availability protection.

## Quick Start

Access the admin at `/railspress/admin`. From there you can manage posts, entities, and blocks.

### Posts

Create posts with rich text, categories, tags, and header images. Build your own frontend controllers and views — see the [Blogging guide](docs/BLOGGING.md).

### Entities

Generate a model and register it:

```bash
bin/rails generate railspress:entity Project title:string client:string description:text
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
bin/rails generate railspress:install                     # Full setup
bin/rails generate railspress:entity Project title:string # Add a managed entity
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
| [Maintenance Commands](docs/MAINTENANCE.md) | Doctor, upgrade, migration, and legacy tasks |
| [Changelog](CHANGELOG.md) | Version history |

## Development

```bash
bundle install
cd spec/dummy && bin/rails db:migrate && cd ../..
bundle exec rspec
```

## License

Available as open source under the terms of the [O'Saasy License](https://osaasy.dev/).

## Trademarks

The Rails trademarks are the intellectual property of David Heinemeier Hansson, and exclusively licensed to the Rails Foundation. Uses of "Rails" and "Ruby on Rails" in this project are for identification purposes only and do not imply an endorsement by or affiliation with Rails, the trademark owner, or the Rails Foundation.
