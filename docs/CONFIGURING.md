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

#### `enable_post_images`

Enables header image uploads for posts. When enabled, posts can have a featured/header image attached via Active Storage.

```ruby
Railspress.configure do |config|
  config.enable_post_images
end
```

**Default:** Disabled

#### `enable_focal_points`

Enables focal point selection for header images. When enabled, editors can set the focal point (important area) of images to control cropping across different aspect ratios.

```ruby
Railspress.configure do |config|
  config.enable_post_images    # Required first
  config.enable_focal_points   # Then enable focal points
end
```

**Default:** Disabled

**Requirements:** Must also enable `enable_post_images`. Requires running migrations for the `railspress_focal_points` table.

See [Image Focal Point System](image-focal-point-system.md) for full documentation including image contexts, per-context overrides, and view helpers.

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

#### `current_author_proc`

Alternative to `current_author_method`. Use a Proc when your current user logic is more complex or uses patterns like `Current` attributes.

```ruby
config.current_author_proc = -> { Current.user }
config.current_author_proc = -> { RequestStore.store[:current_user] }
```

**Default:** `nil` (uses `current_author_method` instead)

### Reading Time

#### `words_per_minute`

Words per minute used for calculating estimated reading time on posts. The reading time is calculated as `word_count / words_per_minute`.

```ruby
config.words_per_minute = 200    # default
config.words_per_minute = 250    # faster readers
config.words_per_minute = 150    # more technical content
```

**Default:** `200`

Access programmatically:

```ruby
Railspress.words_per_minute  # => 200
```

### Blog Path

#### `blog_path`

The public URL path where your blog posts are displayed on your site. This is used to generate "View" links in the admin interface that link to the live post on your frontend.

```ruby
config.blog_path = "/blog"       # default
config.blog_path = "/articles"   # custom path
config.blog_path = "/news"       # news section
config.blog_path = ""            # posts at root (e.g., /my-post-slug)
```

**Default:** `"/blog"`

The admin post show page displays a "View" button for published posts that links to `#{blog_path}/#{post.slug}`.

Access programmatically:

```ruby
Railspress.blog_path  # => "/blog"
```

## Example Configurations

### Minimal Setup (No Authors)

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_post_images
end
```

### With Devise Authentication

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.enable_post_images
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
Railspress.post_images_enabled?    # => true/false
Railspress.focal_points_enabled?   # => true/false
Railspress.author_class            # => User (the actual class)
Railspress.available_authors       # => ActiveRecord::Relation of authors
Railspress.author_display_method   # => :name
Railspress.current_author_method   # => :current_user
Railspress.blog_path               # => "/blog"
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

## Customizing Views

RailsPress uses standard Rails engine view overrides. Copy engine views to your app to customize them.

### Override Specific Views

```bash
# Copy a specific view
mkdir -p app/views/railspress/admin/posts
cp $(bundle show railspress)/app/views/railspress/admin/posts/_form.html.erb \
   app/views/railspress/admin/posts/

# Your app's views take precedence over engine views
```

### Available Partials for Override

| View | Path | Use Case |
|------|------|----------|
| Admin layout | `layouts/railspress/admin.html.erb` | Custom header/footer |
| Sidebar | `railspress/admin/shared/_sidebar.html.erb` | Navigation changes |
| Flash messages | `railspress/admin/shared/_flash.html.erb` | Custom flash styling |
| Post form | `railspress/admin/posts/_form.html.erb` | Add custom fields |
| Entity form | `railspress/admin/entities/_form.html.erb` | Entity form layout |

### Override the Admin Layout

```erb
<!-- app/views/layouts/railspress/admin.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>My Custom Admin</title>
  <%= csrf_meta_tags %>
  <%= stylesheet_link_tag "railspress/admin", "data-turbo-track": "reload" %>
  <%= yield :head %>
</head>
<body class="rp-admin">
  <div class="rp-layout">
    <!-- Your custom sidebar -->
    <%= render "railspress/admin/shared/sidebar" %>

    <main class="rp-main">
      <%= render "railspress/admin/shared/flash" %>
      <%= yield %>
    </main>
  </div>

  <%= javascript_importmap_tags %>
</body>
</html>
```

### Adding Custom Sidebar Links

Override the sidebar partial to add your own navigation:

```erb
<!-- app/views/railspress/admin/shared/_sidebar.html.erb -->
<aside class="rp-sidebar">
  <div class="rp-sidebar__header">
    <h1 class="rp-sidebar__title">My Blog</h1>
  </div>

  <nav class="rp-sidebar__nav">
    <%= link_to "Dashboard", railspress.admin_root_path, class: "rp-sidebar__link" %>
    <%= link_to "Posts", railspress.admin_posts_path, class: "rp-sidebar__link" %>
    <%= link_to "Categories", railspress.admin_categories_path, class: "rp-sidebar__link" %>
    <%= link_to "Tags", railspress.admin_tags_path, class: "rp-sidebar__link" %>

    <!-- Your custom links -->
    <%= link_to "Analytics", main_app.analytics_path, class: "rp-sidebar__link" %>
    <%= link_to "Settings", main_app.settings_path, class: "rp-sidebar__link" %>
  </nav>
</aside>
```

### Customizing Form Fields

Override the post form to add custom fields or change layout:

```erb
<!-- app/views/railspress/admin/posts/_form.html.erb -->
<%= form_with model: [:admin, @post], local: true, class: "rp-form" do |f| %>
  <%= rp_form_errors(@post) %>

  <div class="rp-form__layout">
    <div class="rp-form__main">
      <%= rp_string_field f, :title, autofocus: true %>
      <%= rp_rich_text_field f, :content %>

      <!-- Your custom field -->
      <%= rp_string_field f, :custom_field %>
    </div>

    <div class="rp-form__sidebar">
      <%= rp_sidebar_section "Publishing" do %>
        <%= rp_select_field f, :status, choices: Railspress::Post.statuses.keys %>
      <% end %>
    </div>
  </div>

  <div class="rp-form__actions">
    <%= f.submit "Save", class: "rp-btn rp-btn--primary" %>
  </div>
<% end %>
```

See [Admin Helpers](ADMIN_HELPERS.md) for available helper methods.
