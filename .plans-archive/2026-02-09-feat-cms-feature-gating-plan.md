---
title: CMS Feature Gating and Installer Configuration
type: feat
created: 2026-02-09
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "CMS configuration, route/helper/sidebar/dashboard gating, generator guidance, and both-mode specs are present."
revised: true
---

# CMS Feature Gating and Installer Configuration

## Overview

RailsPress currently loads all features unconditionally — blog, CMS content elements, and inline editing. Host apps that only want blogging still get CMS models, routes, helpers, sidebar links, and JavaScript they don't need. The admin dashboard crashes if CMS tables don't exist.

This plan introduces `config.enable_cms` following the existing `enable_*` pattern, gating CMS behind a single flag.

## Problem Statement

- The admin dashboard crashes if CMS tables don't exist (`ContentGroup.active.count` unconditionally)
- A blog-only host app gets CMS routes, sidebar links, dashboard stats, and helpers it never uses
- No way to adopt blogging without also adopting the full CMS

## Proposed Solution

Two independent feature flags (not "tiers"):

| Flag | Config | What It Enables |
|------|--------|-----------------|
| **CMS** | `config.enable_cms` | Content groups, elements, versions. `cms_element`/`cms_value` helpers. Admin CMS UI. |
| **Inline editing** | `config.inline_editing_check = proc` | Right-click editing on public pages. Requires CMS enabled, `import "railspress"` in application.js, `yield :head` in layout. |

### Configuration API

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.blog_path = "/blog"

  # CMS content elements (opt-in)
  config.enable_cms

  # Inline editing (requires enable_cms)
  config.inline_editing_check = ->(context) {
    context.controller.current_user&.admin?
  }
end
```

Order inside the configure block does not matter. Validation happens after the block completes.

## Implementation

### Step 1: Configuration (`lib/railspress.rb`)

Add `enable_cms` / `cms_enabled?` following the existing pattern exactly:

```ruby
# In Configuration class
attr_reader :cms_enabled

def enable_cms
  @cms_enabled = true
end
```

Add `Railspress.cms_enabled?` convenience accessor (same as `authors_enabled?`, `post_images_enabled?`).

Add `Railspress::ConfigurationError` (simple `StandardError` subclass).

**Post-configure validation** — validate after the entire block executes, not during assignment. This keeps the configure block order-independent:

```ruby
# In Railspress module
def self.configure
  yield(configuration)
  configuration.validate!
end

# In Configuration class
def validate!
  if @inline_editing_check && !@cms_enabled
    raise Railspress::ConfigurationError,
      "Inline editing requires CMS. Add `config.enable_cms` to your initializer."
  end
end
```

### Step 2: Gate the Six Touchpoints

#### 2a. Engine Helper Initializer (`lib/railspress/engine.rb`)

When CMS is enabled, include the full `CmsHelper`. When disabled, include a `DisabledStub` that raises a descriptive `ConfigurationError` — much better DX than a raw `NoMethodError`:

```ruby
initializer "railspress.cms_helper" do
  ActiveSupport.on_load(:action_view) do
    if Railspress.cms_enabled?
      include Railspress::CmsHelper
    else
      include Railspress::CmsHelper::DisabledStub
    end
  end
end
```

The stub:

```ruby
# In app/helpers/railspress/cms_helper.rb
module DisabledStub
  def cms_element(*)
    raise Railspress::ConfigurationError,
      "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer."
  end

  def cms_value(*)
    raise Railspress::ConfigurationError,
      "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer."
  end
end
```

Gate the cache initializer:

```ruby
initializer "railspress.cms_cache" do |app|
  if Railspress.cms_enabled?
    app.config.to_prepare do
      Railspress::CmsHelper.clear_cache
    end
  end
end
```

Add post-configure validation initializer:

```ruby
initializer "railspress.validate_config" do
  if Railspress.inline_editing_check && !Railspress.cms_enabled?
    raise Railspress::ConfigurationError,
      "Inline editing requires CMS. Add `config.enable_cms` to your initializer."
  end
end
```

#### 2b. Routes (`config/routes.rb`)

Wrap CMS resources in `if Railspress.cms_enabled?`. Configuration is available at route-drawing time — the entity registration system already uses this pattern (`Railspress.entity_registered?` in route constraints).

```ruby
# CMS routes (opt-in)
if Railspress.cms_enabled?
  resources :content_groups do ...
  resources :content_elements do ...
  resources :content_element_versions, only: [:show]
  resource :cms_transfer, only: [:show, :create], ...
end
```

#### 2c. Sidebar (`app/views/railspress/admin/shared/_sidebar.html.erb`)

Wrap CMS links in `<% if Railspress.cms_enabled? %>`. The entity section already demonstrates this pattern.

#### 2d. Dashboard Controller + View

**Controller** — guard CMS queries behind `if Railspress.cms_enabled?`:

```ruby
def index
  @posts_count = Post.count
  @categories_count = Category.count
  @tags_count = Tag.count

  if Railspress.cms_enabled?
    @content_groups_count = ContentGroup.active.count
    @content_elements_count = ContentElement.active.count
    @recent_content_elements = ContentElement.active.order(updated_at: :desc).limit(5)
  end

  @recent_posts = Post.order(created_at: :desc).limit(5)
end
```

**View** — wrap CMS stat cards and "Recent Content" section in `<% if Railspress.cms_enabled? %>`.

#### 2e. CMS Module (`Railspress::CMS`)

Raise a clear error when CMS is disabled. Let it fail loudly — if someone calls this without CMS enabled, they have a bug:

```ruby
module CMS
  def self.find(group_name)
    raise Railspress::ConfigurationError,
      "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer." unless Railspress.cms_enabled?
    CMSQuery.new(group_name)
  end
end
```

#### 2f. Admin Layout JavaScript

Keep `import "railspress"` **unconditional** in the admin layout. Blog features (focal point, dropzone, crop) need those controllers. An unused CMS inline editor controller registered but never matched to DOM elements is harmless.

### Step 3: Installer Updates

**`lib/generators/railspress/install/install_generator.rb`**

1. **Remove `import "railspress"` from `configure_javascript`** — blog-only users don't need it on public pages, and the admin layout already loads it
2. **Generate an initializer** — Create `config/initializers/railspress.rb` from template:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  # === Blog Features (always available) ===

  # Author tracking for posts and content elements.
  # Uncomment to enable:
  # config.enable_authors
  # config.author_class_name = "User"
  # config.current_author_method = :current_user

  # === CMS Content Elements (opt-in) ===
  # Adds content groups, content elements, and the cms_element/cms_value
  # view helpers. See docs/CONFIGURING.md for details.
  # Uncomment to enable:
  # config.enable_cms

  # === Inline CMS Editing (requires enable_cms) ===
  # Right-click editing of CMS content on public pages.
  # Also requires: import "railspress" in application.js
  # and yield :head in your layout. See docs/INLINE_EDITING.md.
  # Uncomment to enable:
  # config.inline_editing_check = ->(context) {
  #   context.controller.current_user&.admin?
  # }
end
```

Use a plain `.rb` template file (no ERB interpolation needed, so no `.tt` extension).

3. **Update post-install message** to reference the initializer and mention CMS as opt-in

### Step 4: Documentation + Tests

#### `docs/INLINE_EDITING.md`

Add prerequisite note at the top of Quick Start:

> **Prerequisite:** CMS must be enabled in your initializer (`config.enable_cms`) before configuring inline editing.

#### `docs/CONFIGURING.md`

Add a "CMS Content Elements" section covering:
- `config.enable_cms` — what it enables (content groups, elements, versions, helpers, admin UI)
- What changes in the admin (sidebar links, dashboard stats appear)
- Reference to `docs/INLINE_EDITING.md` for inline editing setup

#### Migrations

**Always copy all migrations.** Unused tables have zero runtime cost. Avoids the "enable later, migrations missing" problem. Consistent with ActionText precedent.

#### Test Strategy

Existing CMS specs need CMS enabled to pass. Add to `spec/rails_helper.rb`:

```ruby
config.before(:each) do
  Railspress.configuration.enable_cms
end

config.after(:each) do
  Railspress.reset_configuration!
end
```

This enables CMS globally for all existing specs (preserving current behavior). New blog-only specs explicitly reset configuration:

```ruby
describe "blog-only mode" do
  before { Railspress.reset_configuration! }

  it "dashboard loads without CMS stats" do ...
  it "sidebar has no CMS links" do ...
  it "CMS routes return 404" do ...
  it "cms_element raises ConfigurationError" do ...
  it "Railspress::CMS.find raises ConfigurationError" do ...
end
```

New config validation spec:

```ruby
describe "configuration validation" do
  it "raises when inline_editing_check set without enable_cms" do
    expect {
      Railspress.configure do |config|
        config.inline_editing_check = ->(ctx) { true }
      end
    }.to raise_error(Railspress::ConfigurationError, /enable_cms/)
  end

  it "allows inline_editing_check with enable_cms in any order" do
    expect {
      Railspress.configure do |config|
        config.inline_editing_check = ->(ctx) { true }
        config.enable_cms
      end
    }.not_to raise_error
  end
end
```

## Acceptance Criteria

### Functional Requirements

- [x] `config.enable_cms` follows the existing `enable_*` pattern
- [x] `Railspress.cms_enabled?` convenience accessor works
- [x] Blog-only mode: admin dashboard loads without errors, no CMS sidebar links, no CMS stat cards
- [x] Blog-only mode: CMS routes return 404
- [x] Blog-only mode: `cms_element`/`cms_value` raise `Railspress::ConfigurationError` with helpful message
- [x] Blog-only mode: `Railspress::CMS.find(...)` raises `Railspress::ConfigurationError`
- [x] CMS enabled: all current CMS functionality works exactly as before
- [x] `inline_editing_check` without `enable_cms` raises `ConfigurationError` (order-independent)
- [x] Installer generates `config/initializers/railspress.rb` with documented options
- [x] Installer does NOT add `import "railspress"` to host app's application.js

### Quality Gates

- [x] All existing specs pass with CMS enabled (no regressions)
- [x] New specs for blog-only mode: dashboard, sidebar, routes, helper stub
- [x] New spec for config validation: order-independent
- [x] Docs updated: INLINE_EDITING.md prerequisite, CONFIGURING.md CMS section

## Files to Modify

| File | Changes |
|------|---------|
| `lib/railspress.rb` | Add `cms_enabled`, `enable_cms`, `cms_enabled?`, `ConfigurationError`, `validate!` |
| `lib/railspress/engine.rb` | Gate `cms_helper` (with DisabledStub), `cms_cache`, add `validate_config` initializer |
| `config/routes.rb` | Wrap CMS resources in `if Railspress.cms_enabled?` |
| `app/views/railspress/admin/shared/_sidebar.html.erb` | Wrap CMS links in `if Railspress.cms_enabled?` |
| `app/controllers/railspress/admin/dashboard_controller.rb` | Guard CMS queries |
| `app/views/railspress/admin/dashboard/index.html.erb` | Guard CMS stat cards and recent content section |
| `app/helpers/railspress/cms_helper.rb` | Add `DisabledStub` module, gate `Railspress::CMS.find` |
| `lib/generators/railspress/install/install_generator.rb` | Generate initializer, remove JS import, update post-install message |
| `docs/CONFIGURING.md` | Add CMS section |
| `docs/INLINE_EDITING.md` | Add `enable_cms` prerequisite note |
| `spec/rails_helper.rb` | Enable CMS in global before block |

## Files to Create

| File | Purpose |
|------|---------|
| `lib/generators/railspress/install/templates/initializer.rb` | Initializer template with documented config options |

## Implementation Order

1. Configuration class changes (`lib/railspress.rb`) — foundation
2. Gate the 6 touchpoints (engine.rb, routes, sidebar, dashboard, CMS module, helper stub)
3. Installer changes — initializer template, remove JS import, update message
4. Documentation — INLINE_EDITING.md, CONFIGURING.md
5. Tests — interleaved with each step, blog-only specs, config validation specs
