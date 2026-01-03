# RailsPress

A simple blog engine for Rails 8 applications.

## Features

- Blog posts with rich text editing (ActionText)
- Categories and tags
- SEO metadata (meta title, meta description)
- Draft/published workflow with automatic publish timestamps
- Admin interface for content management

## Requirements

- Rails 8.0+
- Ruby 3.3+
- ActionText (for rich text)
- Active Storage (for image uploads)

## Installation

Add to your Gemfile:

```ruby
gem "railspress"
```

Install the gem and copy migrations:

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

## Usage

Access the admin interface at `/blog/admin`.

From there you can:
- Create and manage blog posts with rich text content
- Organize posts with categories
- Tag posts (enter tags as comma-separated values)
- Save posts as drafts or publish them

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
