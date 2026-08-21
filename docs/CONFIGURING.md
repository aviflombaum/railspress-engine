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
bin/rails railspress:doctor
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

#### `post_image_variants`

Declares named Active Storage variants for the post `header_image`, so views can request
`@post.header_image.variant(:hero)` instead of repeating transformation options. Each variant is registered
with `format: :webp` automatically.

```ruby
Railspress.configure do |config|
  config.enable_post_images

  config.post_image_variants = {
    hero:  { resize_to_fill: [1920, 1080] },
    card:  { resize_to_fill: [800, 600] },
    thumb: { resize_to_fill: [400, 400] },
    og:    { resize_to_limit: [1200, 630] }
  }
end
```

The hash keys become variant names; the values are passed straight through to Active Storage, so any
transformation it accepts works here.

```erb
<%= image_tag @post.header_image.variant(:hero), alt: @post.title %>
```

**Default:** `{}` (no named variants; inline `variant(resize_to_limit: [...])` calls still work)

Variants are generated on first request and cached as derived blobs. Editing an existing variant's options
changes its key, so the new version is generated on the next request; the old derived file stays in storage
until you purge it.

Variants require an image processor. See [Image variants](#image-variants)
for the gem and native library setup, and [Displaying the Header Image](BLOGGING.md#displaying-the-header-image)
for view examples.

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

#### `enable_cms`

Enables **Blocks** — the copy and images on your site itself (headlines, blurbs, CTAs, hero images). This is one of the three content types RailsPress manages alongside Posts and Entities. When enabled, you get:

- **Content Groups and Content Elements** — the models that power blocks. Groups organize related blocks (e.g., "Homepage Hero"), elements are individual blocks (text or image)
- **Admin UI** — sidebar links for Content Groups, Content Elements, and CMS Transfer appear in the admin
- **Dashboard stats** — Content Groups and Content Elements counts on the admin dashboard
- **View helpers** — `cms_element` and `cms_value` become available in your host app views
- **Chainable API** — `Railspress::CMS.find("Group").load("Element").value` for use in controllers and services

```ruby
Railspress.configure do |config|
  config.enable_cms
end
```

**Default:** Disabled

When CMS is disabled, calling `cms_element` or `cms_value` in a view raises `Railspress::ConfigurationError` with a helpful message. CMS routes are not mounted and CMS links do not appear in the admin sidebar.

**Image content elements** support drag-and-drop uploads via the dropzone UI, per-element focal points (when `enable_focal_points` is also active), and an `image_hint` field for documenting recommended dimensions. Content type is locked after creation. In views, `cms_element` automatically outputs an `<img>` tag with `object-position` CSS derived from the focal point.

**Inline editing** builds on top of CMS. See [Inline Editing](INLINE_EDITING.md) for how to enable right-click editing of CMS content on public pages.

#### `enable_api`

Enables the RailsPress JSON API (`/api/v1`) and admin API key management pages.

```ruby
Railspress.configure do |config|
  config.enable_api
end
```

**Default:** Disabled

When enabled:
- API endpoints are available under `/blog/api/v1/*` (assuming engine mounted at `/blog`)
- API key management is available at `/blog/admin/api_keys`

**Requirement:** all three Active Record Encryption credentials must be configured by the host application. When `config.enable_api` is enabled, RailsPress checks the effective Rails credentials/configuration during boot and raises `Railspress::ConfigurationError` if any value is missing. RailsPress never generates or writes these secrets.

Generate the standard Rails credentials snippet:

```bash
bin/rails db:encryption:init
```

Store the generated `primary_key`, `deterministic_key`, and `key_derivation_salt` in the host application's Rails credentials or secret-management/deployment system. Rails automatically reads this credentials shape:

```yaml
active_record_encryption:
  primary_key: ...
  deterministic_key: ...
  key_derivation_salt: ...
```

Explicit environment-backed Rails configuration is also supported when the deployment platform owns the values:

```ruby
Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
```

The install generator detects both forms. It confirms when configuration is present and prints `bin/rails db:encryption:init` only when values are missing.

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

This method must be available on the host `ApplicationController`. RailsPress browser controllers inherit from it, so Devise-style `current_user` helpers work without extra integration. For non-method lookup flows, use `current_author_proc`.

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
config.current_author_proc = -> {
  Session.find_by(id: cookies.signed[:session_id])&.user
}
```

**Default:** `nil` (uses `current_author_method` instead)

### Admin Authentication

RailsPress browser controllers inherit the host application's `ApplicationController`. RailsPress API controllers deliberately do not: they inherit from `ActionController::API` and enforce RailsPress bearer-token authentication.

#### `admin_authentication_method`

The host controller method RailsPress calls before every admin action. This can be any private or public method already defined by the host authentication system.

```ruby
config.admin_authentication_method = :require_admin!
# or Devise:
config.admin_authentication_method = :authenticate_user!
```

Leave this unset only if an inherited `ApplicationController` callback already protects RailsPress admin requests. RailsPress raises `Railspress::ConfigurationError` with the configured method name if the method is unavailable.

**Default:** `nil`

#### `current_admin_method`

The host controller method that returns the signed-in administrator. RailsPress uses this identity to own and audit API key lifecycle actions; it is separate from the authentication method because many auth systems expose these as separate methods.

```ruby
config.current_admin_method = :current_user  # default
config.current_admin_method = :current_admin
```

**Default:** `:current_user`

#### `current_admin_proc`

Alternative to `current_admin_method` for request-scoped `Current`, session, or custom authentication state.

```ruby
config.current_admin_proc = -> { Current.user }
```

**Default:** `nil` (uses `current_admin_method` instead)

`current_api_actor_method`, `current_api_actor_proc`, and the `current_api_actor` controller helper remain compatibility aliases in RailsPress 1.x. They emit deprecation warnings and will be removed in RailsPress 2.0; use `current_admin_method`, `current_admin_proc`, and `current_railspress_admin` instead.

#### `admin_auth_concern`

Optional host-app concern to include directly into `Railspress::Admin::BaseController`. Most applications no longer need this because RailsPress browser controllers inherit the host `ApplicationController`. It remains available for auth behavior intentionally isolated in a concern that is not included by `ApplicationController`.

Set this to a concern constant name (String/Symbol) or Module.

```ruby
config.admin_auth_concern = "RailspressAdminAuth"
config.admin_auth_concern = :railspress_admin_auth
```

Example host concern:

```ruby
# app/controllers/concerns/railspress_admin_auth.rb
module RailspressAdminAuth
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :require_admin!
  end

  private

  def require_admin!
    redirect_to main_app.root_path, alert: "Not authorized." unless current_user&.admin?
  end
end
```

**Default:** `nil` (no concern is included)

#### `public_base_url`

Optional canonical base URL used in admin-generated API/agent instructions.

RailsPress also uses this URL to derive site-scoped local token filenames in those instructions. The full hostname, non-default port, and base path are retained, so separate RailsPress applications do not share a token file.

If not set, RailsPress resolves the URL in this order:

1. `Rails.application.routes.default_url_options` (host/protocol/port/script_name)
2. Current request base URL (`request.base_url`)

```ruby
config.public_base_url = "https://blog.example.com"
```

**Default:** `nil`

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
Railspress.cms_enabled?            # => true/false
Railspress.api_enabled?            # => true/false
Railspress.author_class            # => User (the actual class)
Railspress.available_authors       # => ActiveRecord::Relation of authors
Railspress.author_display_method   # => :name
Railspress.current_author_method   # => :current_user
Railspress.admin_authentication_method # => :require_admin!
Railspress.current_admin_method    # => :current_user
Railspress.blog_path               # => "/blog"
```

## Adding Authentication

RailsPress does not impose an authentication library. Its browser controllers inherit the host `ApplicationController`, and the initializer names the host methods RailsPress should use:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.admin_authentication_method = :require_admin!
  config.current_admin_method = :current_user
  config.current_author_method = :current_user
end
```

`require_admin!` and `current_user` belong to the host application and may be private. RailsPress makes no assumptions about whether they come from Devise, another gem, or custom controller code. If your host already has a global inherited callback that protects RailsPress, omit `admin_authentication_method` to avoid calling it twice.

For `Current` or custom request-scoped identity, configure proc hooks:

```ruby
Railspress.configure do |config|
  config.current_author_proc = -> { Current.user }
  config.current_admin_proc = -> { Current.user }
end
```

Mount RailsPress normally:

```ruby
Rails.application.routes.draw do
  mount Railspress::Engine => "/railspress"
end
```

Do not put the whole engine behind a session-only route constraint. Route constraints run before controllers, so they prevent bearer-token requests from reaching `/railspress/api/*`. The normal mount is safe when `admin_authentication_method` (or an inherited callback) protects browser routes: API routes use their separate bearer-authenticated controller stack.

Run `bin/rails railspress:doctor` after changing authentication or API configuration. It verifies explicit method/concern resolution, encryption settings, the resolved mount, and RailsPress migration state. When authentication is inherited or enforced outside Rails controllers, doctor warns because it cannot prove the semantics; verify the reported admin URL while signed out.

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

### Image variants

When your application uses resized header images or passes a `variant:` option to `rp_featured_image_url`, Active Storage also needs an image-processing backend. RailsPress supplies `image_processing >= 2.0.3`; the host application chooses and installs the processor gem and native library.

Choose one processor:

```ruby
# Gemfile
# Recommended for Rails 8.1.3.1+ applications
gem "ruby-vips", "~> 2.2", ">= 2.2.1"

# Or use ImageMagick instead
# gem "mini_magick", "~> 5.0"
```

Install the matching system package in development, test, and production: libvips `8.13+` for `ruby-vips`, or ImageMagick for `mini_magick`. Rails selects a processor from your application defaults; set it explicitly when needed:

```ruby
# config/application.rb
config.active_storage.variant_processor = :vips       # libvips
# config.active_storage.variant_processor = :mini_magick # ImageMagick
```

The `image_processing` gem alone is not enough: it needs one of the processor gems and its native library. Rails 8.1.3.1 disables unsafe libvips operations at boot; that protection requires ruby-vips `2.2.1+` and libvips `8.13+`. See the [Rails Active Storage guide](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images) for platform-specific installation details.

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

## Dependencies

### Stimulus

RailsPress depends on `stimulus-rails >= 1.2.2`, the first gem release that packages Stimulus 3.2.2. This preserves the Stimulus runtime RailsPress previously loaded from JSPM while serving it locally through the host asset pipeline.

For importmap applications, the engine supplies:

```ruby
pin "@hotwired/stimulus", to: "stimulus.min.js"
```

No host CDN pin is required. Engine importmaps load before the host's `config/importmap.rb`, so an intentional host `@hotwired/stimulus` pin overrides the RailsPress default. RailsPress does not start a second Stimulus application; continue starting Stimulus in the host JavaScript entrypoint and importing `railspress` to register its controllers.

RailsPress admin CSS also uses a system serif stack rather than downloading Google Fonts. The default admin interface therefore makes no runtime JavaScript or font CDN requests.

### Lexxy (Rich Text Editor)

RailsPress uses [Lexxy](https://github.com/basecamp/lexxy), Basecamp's rich text editor built on Meta's Lexical framework. It replaces the default Trix editor that ships with ActionText.

RailsPress depends on and auto-wires Lexxy and is tested with Lexxy `0.9.29`. Do not add a Lexxy dependency or importmap pin to the host application. To explicitly unlock the engine-managed dependency in an existing bundle:

```bash
bundle update lexxy
```

Lexxy is auto-wired by RailsPress:

- Engine importmap auto-pins `lexxy`
- RailsPress admin layout auto-imports `railspress` (which imports Lexxy)

You only need `import "railspress"` in your host `application.js` for host-page features like inline CMS editing.

**Note:** Lexxy is only loaded in the admin interface. It is not loaded on public-facing pages unless you explicitly import it.

#### Keeping Lexxy Updated

Check for new versions:

```bash
gem search lexxy --remote
```

Lexxy is under active development at Basecamp. New versions may include editor improvements, bug fixes, and Ruby compatibility updates. Update periodically:

```bash
bundle update lexxy
bundle exec rspec  # Verify nothing broke
```

If a Lexxy update introduces breaking changes to the editor, you can pin to a specific version in your host app's Gemfile:

```ruby
# Gemfile
gem "lexxy", "= 0.9.29"  # Example exact pin; choose a version tested in your app
```

### Other Dependencies

| Gem | Purpose |
|-----|---------|
| `rails >= 8.1.3.1` | Framework (includes the Active Storage security fix) |
| `lexxy >= 0.9.29` | Rich text editor (replaces Trix) |
| `image_processing >= 2.0.3, < 3` | Secure Active Storage transformation dispatch |
| `rubyzip >= 2.3` | ZIP file handling for CMS import/export |
| `redcarpet >= 3.6` | Markdown parsing for post import |
| `ssrf_filter ~> 1.5` | SSRF-safe remote post image fetching |
