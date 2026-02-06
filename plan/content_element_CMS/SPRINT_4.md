# Sprint 4: CMS Helper API & Host Integration

## Goal

Create the `Railspress::CmsHelper` module that provides the chainable API for loading content in host application views. This is how developers actually use the CMS content in their templates.

## Tasks

### 4.1 Create CmsHelper Module

**File**: `app/helpers/railspress/cms_helper.rb`

Adapted from `innovent-rails/app/helpers/cms_helper.rb`. Provides:

**Chainable API (CMSQuery class)**:
```ruby
Railspress::CMS.find("Homepage").load("Hero H1").value
Railspress::CMS.find("Homepage").load("Hero H1").element
```

**Helper methods** (included in views):
```ruby
cms_value("Homepage", "Hero H1")      # Returns the text value
cms_element(group: "Homepage", name: "Hero H1")  # Returns value or wraps with inline editor
cms_element(group: "Homepage", name: "Hero H1") do |value|
  content_tag(:h1, value, class: "hero-title")
end
```

**Request-level caching**:
- Cache queries within a single request to avoid N+1
- `Railspress::CmsHelper.clear_cache` to reset

### 4.2 Create CMS Module Constant

**File**: Part of `app/helpers/railspress/cms_helper.rb` or `lib/railspress/cms.rb`

```ruby
module Railspress
  module CMS
    def self.find(group_name)
      Railspress::CmsHelper::CMSQuery.new.find(group_name)
    end
  end
end
```

### 4.3 Register Helper in Engine

**File**: Update `lib/railspress/engine.rb`

Ensure `Railspress::CmsHelper` is available to host applications:
```ruby
initializer "railspress.helpers" do
  ActiveSupport.on_load(:action_view) do
    include Railspress::CmsHelper
  end
end
```

### 4.4 Add Install Generator Note

Update documentation to show host apps how to use CMS content:

```ruby
# In any view:
<h1><%= cms_value("Homepage", "Hero Title") %></h1>

# With block for custom rendering:
<%= cms_element(group: "Homepage", name: "Hero Title") do |value| %>
  <h1 class="text-4xl"><%= value %></h1>
<% end %>

# Chainable API (also works in controllers/services):
Railspress::CMS.find("Homepage").load("Hero Title").value
```

## Acceptance Criteria

- [ ] `Railspress::CMS.find("group").load("element").value` returns correct text
- [ ] `cms_value("group", "element")` works in views
- [ ] `cms_element` with block renders correctly
- [ ] Returns nil gracefully for missing groups/elements
- [ ] Caching prevents duplicate queries in same request
- [ ] `Railspress::CmsHelper.clear_cache` resets cache
- [ ] Helper is auto-included in host app views

## Dependencies

- Sprint 1 (models - ContentGroup, ContentElement)
