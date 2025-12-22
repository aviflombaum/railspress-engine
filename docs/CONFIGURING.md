# Configuring RailsPress

This guide covers all configuration options for RailsPress.

## Basic Setup

### 1. Mount the Engine

Add to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Railspress::Engine => "/blog", as: :railspress
end
```

The admin interface will be available at `/blog/admin`.

### 2. Install Migrations

```bash
bin/rails railspress:install:migrations
bin/rails db:migrate
```

### 3. Create Initializer

Create `config/initializers/railspress.rb`:

```ruby
Railspress.configure do |config|
  # Configuration options go here
end
```

## Configuration Options

### Feature Toggles

#### `enable_authors`

Enables author/user association for posts. When enabled, posts can be assigned to authors and the author dropdown appears in the post form.

```ruby
Railspress.configure do |config|
  config.enable_authors
end
```

**Default:** Disabled

#### `enable_header_images`

Enables header image uploads for posts. When enabled, posts can have a featured/header image attached via Active Storage.

```ruby
Railspress.configure do |config|
  config.enable_header_images
end
```

**Default:** Disabled

### Author Configuration

These options are only relevant when `enable_authors` is called.

#### `author_class_name`

The class name of your user/author model as a string.

```ruby
config.author_class_name = "User"        # default
config.author_class_name = "Admin"       # custom model
config.author_class_name = "Author"      # dedicated author model
```

**Default:** `"User"`

#### `current_author_method`

The controller method that returns the currently signed-in user. This integrates with your authentication system (Devise, Clearance, custom auth, etc.).

```ruby
config.current_author_method = :current_user   # default (Devise)
config.current_author_method = :current_admin  # admin-specific
config.current_author_method = :logged_in_user # custom auth
```

**Default:** `:current_user`

#### `author_scope`

Limits which users appear in the author dropdown. Accepts a Symbol (scope name) or a Proc.

```ruby
# Use a scope defined on the User model
config.author_scope = :authors           # calls User.authors
config.author_scope = :active            # calls User.active

# Use a Proc for complex logic
config.author_scope = ->(klass) { klass.where(role: "writer") }
config.author_scope = ->(klass) { klass.joins(:profile).where(profiles: { can_publish: true }) }
```

**Default:** `nil` (returns all records)

#### `author_display_method`

The method called on author objects to display their name in dropdowns and post listings.

```ruby
config.author_display_method = :name       # default
config.author_display_method = :full_name
config.author_display_method = :email
config.author_display_method = :display_name
```

**Default:** `:name`

## Example Configurations

### Minimal Setup (No Authors)

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_header_images
end
```

### With Devise Authentication

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.enable_header_images
  config.author_class_name = "User"
  config.current_author_method = :current_user
  config.author_display_method = :email
end
```

### With Scoped Authors

```ruby
# app/models/user.rb
class User < ApplicationRecord
  scope :writers, -> { where(role: %w[writer editor admin]) }

  def display_name
    "#{first_name} #{last_name}"
  end
end

# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.author_class_name = "User"
  config.author_scope = :writers
  config.author_display_method = :display_name
end
```

### Multi-tenant Setup

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.author_scope = ->(klass) { klass.where(organization_id: Current.organization_id) }
end
```

## Accessing Configuration

You can check configuration values programmatically:

```ruby
Railspress.authors_enabled?        # => true/false
Railspress.header_images_enabled?  # => true/false
Railspress.author_class            # => User (the actual class)
Railspress.available_authors       # => ActiveRecord::Relation of authors
Railspress.author_display_method   # => :name
Railspress.current_author_method   # => :current_user
```

## Adding Authentication

RailsPress does not include authentication. Protect the admin area by configuring your application controller:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # If using Devise
  before_action :authenticate_user!, if: :railspress_admin?

  private

  def railspress_admin?
    request.path.start_with?("/blog/admin")
  end
end
```

Or override the RailsPress base controller:

```ruby
# config/initializers/railspress.rb
Rails.application.config.to_prepare do
  Railspress::Admin::BaseController.class_eval do
    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      redirect_to root_path unless current_user&.admin?
    end
  end
end
```

## Required Model Methods

When enabling authors, ensure your author model responds to the `author_display_method`:

```ruby
class User < ApplicationRecord
  # If using author_display_method = :name (default)
  def name
    "#{first_name} #{last_name}".strip
  end
end
```

## Active Storage Setup

Header images use Active Storage. Ensure it's configured:

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Configure your storage service in `config/storage.yml` and set `config.active_storage.service` in your environment files.
