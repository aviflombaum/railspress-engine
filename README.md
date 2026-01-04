# RailsPress

A simple blog engine for Rails 8 applications.

## Features

- Blog posts with rich text editing (Lexxy editor)
- Categories and tags
- SEO metadata (meta title, meta description)
- Draft/published workflow with automatic publish timestamps
- Admin interface for content management
- **Entity System** - Manage any ActiveRecord model through the admin ([docs](docs/ENTITIES.md))
- **Import/Export** - Bulk markdown operations with YAML frontmatter ([docs](docs/IMPORT_EXPORT.md))
- **Theming** - CSS variable customization ([docs](docs/THEMING.md))

## Requirements

- Rails 8.0+
- Ruby 3.3+
- ActionText (for rich text)
- Active Storage (for image uploads)

## Installation

### Prerequisites

Ensure ActionText and Active Storage are installed in your application:

```bash
rails action_text:install
rails active_storage:install
rails db:migrate
```

### Install RailsPress

Add to your Gemfile:

```ruby
gem "railspress"
```

Run the install generator (recommended):

```bash
bundle install
rails generate railspress:install
rails db:migrate
```

Or manually copy migrations:

```bash
bundle install
rails railspress:install:migrations
rails db:migrate
```

Mount the engine in your routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Railspress::Engine => "/blog", as: :railspress
end
```

## Authentication

**Important:** The admin interface is publicly accessible by default. You must configure authentication before deploying to production.

Add authentication to your application controller:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, if: :railspress_admin?

  private

  def railspress_admin?
    request.path.start_with?("/blog/admin")
  end
end
```

See [CONFIGURING.md](docs/CONFIGURING.md) for more authentication patterns.

## Usage

Access the admin interface at `/blog/admin`.

From there you can:
- Create and manage blog posts with rich text content
- Organize posts with categories
- Tag posts (enter tags as comma-separated values)
- Save posts as drafts or publish them

## Generators

```bash
# Full installation (migrations, importmap, routes)
rails generate railspress:install

# Add a custom entity (managed through admin)
rails generate railspress:entity Project title:string description:text content:rich_text
```

## Documentation

- **[Getting Started](docs/README.md)** - Quick reference and models
- **[Entity System](docs/ENTITIES.md)** - Manage custom models through admin
- **[Building a Blog](docs/BLOGGING.md)** - Frontend controllers and views
- **[Configuration](docs/CONFIGURING.md)** - Authors, images, and options
- **[Import/Export](docs/IMPORT_EXPORT.md)** - Bulk operations
- **[Theming](docs/THEMING.md)** - CSS customization
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common errors

## Development

After checking out the repo:

```bash
bundle install
cd spec/dummy && bundle exec rails db:migrate && cd ../..
bundle exec rspec
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Trademarks

The Rails trademarks are the intellectual property of David Heinemeier Hansson, and exclusively licensed to the Rails Foundation. Uses of "Rails" and "Ruby on Rails" in this project are for identification purposes only and do not imply an endorsement by or affiliation with Rails, the trademark owner, or the Rails Foundation.
