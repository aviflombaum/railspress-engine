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

Install and apply the complete migration history, including migrations for optional features that are currently disabled. Feature toggles control runtime routes and behavior; they do not select which RailsPress migrations belong in the host application.

### 3. Create Initializer

Create `config/initializers/railspress.rb`:

```ruby
Railspress.configure do |config|
  config.enable_post_images
  config.enable_focal_points
  config.enable_cms
end
```

Those three features are the recommended defaults written by the install generator for new applications. The library defaults remain disabled, so existing applications and applications with a hand-written initializer do not change behavior during an upgrade. The generated initializer also includes concise defaults and examples for every supported setting.

### What the Install Generator Changes

For a new host application, the generator performs the setup steps above and fills in framework prerequisites when they are missing:

```bash
bin/rails generate railspress:install
```

| Target | Generator behavior |
|--------|--------------------|
| RailsPress migrations | Invokes `railspress:install:migrations` to copy missing engine migrations |
| Action Text migrations | Copies them only when no `create_action_text_tables` migration exists |
| Active Storage migrations | Copies them only when no `create_active_storage_tables` migration exists |
| `config/routes.rb` | Adds `mount Railspress::Engine => "/railspress"` unless an engine mount already exists |
| `config/importmap.rb` | Adds the Active Storage ESM pin when importmap is installed and the pin is absent |
| RailsPress initializer | Creates the documented template, with post images, post focal points, and CMS enabled, only when the file is absent |

The generator copies every missing RailsPress migration but does not run `db:migrate`. Its initializer enables the recommended post-image, focal-point, and CMS features for new installations; host-dependent features remain opt-in.

The generator detects an existing RailsPress route, initializer, or copied migration and changes its final message to the upgrade workflow. Rerunning it can fill in missing setup, but it is not a replacement for reviewing [Upgrading](UPGRADING.md) and the installed version's release notes.

## Configuration Options

### Feature Dependency Matrix

Core Post, Category, and Tag models and their admin CRUD are always available. The following settings add optional behavior:

The prerequisites column describes what an enabled feature uses at runtime. It is not a migration-installation matrix: every shipped RailsPress migration should be copied and applied in every host, including migrations for disabled features.

| Setting | Default | Prerequisites | What it enables | Disabled behavior |
|---------|---------|---------------|-----------------|-------------------|
| `enable_authors` | Off | Configured author class and current-author method/proc | Author selection and `author_id` lookup for Posts/CMS records | Author accessors return no author and admin author inputs are omitted; API response keys remain stable |
| `enable_post_images` | Off | Active Storage; processor gem/native library only when variants are requested | Post header/gallery attachments in admin and API | Post media API returns `404`; serialized media values are `null` |
| `enable_focal_points` | Off | Standard complete migration install; Post focal UI/API also requires post images | Post header focal point and context API/UI | Post focal/context API returns `404` |
| `enable_cms` | Off | Standard complete migration install | Content groups/elements, CMS transfer routes, and host CMS helpers | CMS routes are not drawn; disabled helper stubs raise `ConfigurationError` |
| `inline_editing_check` | `nil` | CMS, `import "railspress"`, `yield :head`, and a proc returning true | Right-click inline editing for text blocks | No inline wrapper/menu is rendered |
| `enable_api` | Off | Standard complete migration install and configured current-admin identity | Bearer API and admin key-management navigation | API and key-management requests answer `404` and navigation is hidden |

The focal-point model concern is reusable outside Post feature gating. Entities declared with `focal_point_image` and CMS image elements use the shared focal-point table and editor directly. `enable_focal_points` specifically gates the optional Post header-image focal-point UI and API serialization/endpoints.

Routes behave differently by subsystem: CMS routes are conditionally drawn when the engine route set loads, while versioned API routes remain recognizable and the API base controller returns `404` when Agents & API is disabled.

Configuration validation runs after the host initializer block. An inline-editing proc without CMS raises `Railspress::ConfigurationError`.

The defaults in the matrix above are library defaults. The install generator explicitly enables post images, post focal points, and CMS in a newly generated initializer. It never overwrites an existing initializer.

#### Common Feature Recipes

| Goal | Configuration and host setup |
| --- | --- |
| Blog only | No feature toggle is required; install migrations and protect the admin |
| Blog with header/gallery media | `config.enable_post_images`, Active Storage, and an image processor only when requesting variants |
| CMS blocks | Complete the standard migration install, then set `config.enable_cms` |
| CMS with inline editing | CMS plus `config.inline_editing_check`, `import "railspress"`, and `yield :head` in the public layout |
| Entity focal images | Complete the standard migration install and declare `focal_point_image` on an entity; the Post image toggle is not required |
| Agents & API | Complete the standard migration install, set `config.enable_api`, provide all three encryption values, use a normal engine mount, and protect browser admin routes |

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

Declares named Active Storage variants for the post `header_image` and `gallery_images`, so views can request
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

The hash keys become variant names; the values are passed to Active Storage and RailsPress adds `format: :webp`. Any transformation accepted by the configured processor can be used.

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

**Post requirement:** Post header-image focal points require `enable_post_images`. Entity focal-point fields and CMS image elements use the same focal-point model support without reading the Post image toggle. All uses require the `railspress_focal_points` migration.

See [Image Focal Point System](image-focal-point-system.md) for full documentation including image contexts, per-context overrides, and view helpers.

#### `image_contexts`, `add_image_context`, and `remove_image_context`

Image contexts describe the aspect ratios and output sizes used by focal-point overrides. The defaults are `hero` (`16:9`), `card` (`4:3`), and `thumb` (`1:1`). Replace the full hash or modify it through the configuration helpers:

```ruby
config.image_contexts = {
  hero: { aspect: [16, 9], label: "Hero", sizes: [1920, 1280] }
}
config.add_image_context :portrait, aspect: [3, 4], label: "Portrait", sizes: [900]
config.remove_image_context :hero
```

Replacing the hash normalizes its top-level keys to symbols. Each context should supply an `aspect` pair; `label` and `sizes` are used in the admin/API presentation. Changing contexts does not rewrite stored overrides, so remove or rename a context only after checking existing focal-point data and clients.

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

**Image content elements** support drag-and-drop uploads via the dropzone UI, per-element focal points, and an `image_hint` field for documenting recommended dimensions. Content type is locked after creation. In views, `cms_element` automatically outputs an `<img>` tag with `object-position` CSS derived from the focal point.

**Inline editing** builds on top of CMS. See [Inline Editing](INLINE_EDITING.md) for how to enable right-click editing of CMS content on public pages.

#### `inline_editing_check`

Assign a proc that receives the helper context and returns whether inline CMS editing should render for the current request:

```ruby
config.enable_cms
config.inline_editing_check = ->(context) { context.controller.current_user&.admin? }
```

Setting this without enabling CMS raises `Railspress::ConfigurationError` after the configure block. Public layouts using inline editing must also import `railspress` JavaScript and include `yield :head`; see [Inline Editing](INLINE_EDITING.md) for the full setup. The default is `nil`, which disables inline editing.

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

API keys and Agent Setup Keys are revealed once when issued. RailsPress stores their prefix and keyed digest for verification; it cannot recover the original token from the database. The host application's own encrypted models and encryption configuration are independent of RailsPress.

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
config.blog_path = "/posts"      # posts route
config.blog_path = "/articles"   # custom path
config.blog_path = "/news"       # news section
config.blog_path = ""            # posts at root (e.g., /my-post-slug)
```

**Default:** `"/blog"`

The admin post show page displays a "View" button for posts that are published and whose `published_at` time has arrived. The button links to `<blog_path>/<post.slug>`. Draft and scheduled posts do not display this ordinary public link.

Access programmatically:

```ruby
Railspress.blog_path  # => "/blog"
```

### Shareable Post Previews

#### `enable_post_previews`

Enables signed, expiring "Preview" links for draft and scheduled posts. This is disabled by default because the host blog controller must explicitly resolve preview tokens before the links will work.

Follow the complete [host-controller integration](BLOGGING.md#shareable-draft-previews), then enable previews:

```ruby
config.enable_post_previews
```

Preview URLs use the configured `blog_path`, the post slug, and a compact, signed `railspress_preview` query parameter. Live posts continue displaying the ordinary "View" link.

#### `post_preview_expires_in`

Controls the lifetime embedded in newly generated preview tokens:

```ruby
config.post_preview_expires_in = 24.hours # default
config.post_preview_expires_in = 3.days
```

The value must be a positive duration. Changing it affects newly generated links; signed links retain the expiration embedded when they were created. Removing `config.enable_post_previews` prevents all preview tokens from resolving, including tokens that have not yet expired.

Programmatic APIs:

```ruby
Railspress.post_previews_enabled?      # => true/false
Railspress.post_preview_expires_in     # => 24.hours
Railspress.public_post_path(post)      # => "/posts/my-draft"
Railspress.post_preview_path(post)     # => "/posts/my-draft?railspress_preview=..."

post.preview_token
Railspress::Post.find_preview!(slug: post.slug, token: token)
```

Preview URLs are bearer credentials. Anyone with the URL can view the signed post until the token expires. Use HTTPS and share links only with intended reviewers. Invalid, expired, wrong-purpose, deleted-record, and slug-mismatched tokens return 404. Ordinary requests without a token must continue querying `Railspress::Post.published`; never replace the public action with an unscoped lookup.

### Entity Index Defaults

#### `default_index_columns`

Sets the fallback columns for registered entities that do not define `RAILSPRESS_INDEX_COLUMNS` or `railspress_index_columns`:

```ruby
config.default_index_columns = %i[id title name created_at]
```

RailsPress keeps only columns the entity actually has. Entity-level configuration takes precedence. The default is `%i[id title name created_at]`; see [Entities](ENTITIES.md) for model registration and per-model field/index configuration.

### Entity Registration

#### `register_entity`

Registers a host model for the generic admin entity UI. String or symbol registration is preferred because it resolves the class again after Rails reloads:

```ruby
config.register_entity "Project"
config.register_entity :admin_portfolio, label: "Work Samples"
```

The model must include `Railspress::Entity`. Use `Railspress.registered_entities`, `Railspress.entity_for(route_key)`, and `Railspress.entity_registered?(route_key)` for read-only registry access. See [Entities](ENTITIES.md) for generator and model setup.

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
Railspress.post_previews_enabled?  # => true/false
Railspress.post_preview_expires_in # => 24.hours
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
Railspress.public_base_url         # => nil or configured canonical URL
Railspress.post_image_variants     # => configured named-variant hash
Railspress.image_contexts          # => hero/card/thumb definitions by default
Railspress.inline_editing_check    # => nil or configured Proc
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

Run `bin/rails railspress:doctor` after changing the initializer, authentication, or API configuration. Before boot, it checks that `config/initializers/railspress.rb` exists and parses as Ruby. During boot it identifies settings that raise; afterward it reports RailsPress validation errors and deprecated settings. It also verifies explicit method/concern resolution, encryption settings, the resolved mount, and that every shipped RailsPress migration is copied and applied. Warnings and failures include suggested next actions. When authentication is inherited or enforced outside Rails controllers, doctor warns because it cannot prove the semantics; verify the reported admin URL while signed out. See [Maintenance Commands](MAINTENANCE.md#railspressdoctor) for exit statuses, terminal colors, `NO_COLOR`, and unexpected-error handling.

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
cp "$(bundle info --path railspress-engine)/app/views/railspress/admin/posts/_form.html.erb" \
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

Copy the current engine layout before modifying it. Preserve the Lexxy and `railspress/application` stylesheet tags, CSRF/CSP tags, importmap tags, `import "railspress"`, and the two packaged admin/Markdown scripts. The current layout uses `.rp-admin-layout`, `.rp-sidebar`, and `.rp-main`; compare an override with the engine copy during each upgrade.

### Adding Custom Sidebar Links

Override the sidebar partial to add your own navigation:

```erb
<!-- app/views/railspress/admin/shared/_sidebar.html.erb -->
<div class="rp-sidebar-content">
  <!-- Preserve the current engine header and standard navigation links. -->
  <nav class="rp-nav">
    <%= link_to main_app.analytics_path, class: "rp-nav-link" do %>
      <span class="rp-nav-icon" aria-hidden="true">A</span>
      <span class="rp-nav-text">Analytics</span>
    <% end %>
  </nav>
</div>
```

### Customizing Form Fields

Override the post form to add custom fields or change layout:

```erb
<!-- app/views/railspress/admin/posts/_form.html.erb -->
<%= form_with model: [:admin, @post], local: true, class: "rp-form" do |f| %>
  <%= rp_form_errors(@post) %>

  <div class="rp-form-layout">
    <div class="rp-form-main">
      <%= rp_string_field f, :title, autofocus: true %>
      <%= rp_rich_text_field f, :content %>

      <!-- Your custom field -->
      <%= rp_string_field f, :custom_field %>
    </div>

    <div class="rp-form-sidebar">
      <%= rp_sidebar_section "Publishing" do %>
        <%= rp_select_field f, :status, choices: Railspress::Post.statuses.keys %>
      <% end %>
    </div>
  </div>

  <div class="rp-form-actions">
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
