# Sprint 2: Admin Controllers & Routes

## Goal

Create the admin controllers for ContentGroups, ContentElements, and ContentElementVersions, and wire up all routes. This provides the backend CRUD operations.

## Tasks

### 2.1 Add Content Routes

**File**: `config/routes.rb`

Add to the existing `namespace :admin` block:

```ruby
resources :content_groups
resources :content_elements do
  member do
    get :inline  # For future inline editing
  end
end
resources :content_element_versions, only: [:show]
```

### 2.2 Create ContentGroupsController

**File**: `app/controllers/railspress/admin/content_groups_controller.rb`

Inherits from `Railspress::Admin::BaseController`. Actions:
- `index` - list active groups with element counts
- `show` - display group with its elements
- `new` / `create` - create new group
- `edit` / `update` - update group
- `destroy` - soft delete group

Adapted from `innovent-rails/app/controllers/admin/content_groups_controller.rb`:
- Remove Kaminari pagination (use simple `.limit()`)
- Remove excessive error rescue blocks (keep simple)
- Use `Railspress::ContentGroup` namespace
- Use engine route helpers

### 2.3 Create ContentElementsController

**File**: `app/controllers/railspress/admin/content_elements_controller.rb`

Inherits from `Railspress::Admin::BaseController`. Actions:
- `index` - list active elements, filterable by group
- `show` - display element with version history
- `new` / `create` - create new element (with group pre-selection)
- `edit` / `update` - update element (triggers auto-versioning)
- `destroy` - soft delete element
- `inline` - Turbo Frame endpoint for inline editing (Sprint 7)

Adapted from `innovent-rails/app/controllers/admin/content_elements_controller.rb`:
- Namespace to `Railspress::Admin`
- Remove Kaminari, use `.limit()`
- Turbo Stream support for inline updates
- Clear CMS cache on update

### 2.4 Create ContentElementVersionsController

**File**: `app/controllers/railspress/admin/content_element_versions_controller.rb`

Read-only controller with `show` action only. Displays version details.

## Acceptance Criteria

- [ ] `GET /admin/content_groups` returns 200
- [ ] Full CRUD works for content groups
- [ ] Full CRUD works for content elements
- [ ] Creating/updating a content element creates a version
- [ ] Deleting uses soft delete (not hard delete)
- [ ] Content elements can be filtered by group
- [ ] Version show page accessible

## Dependencies

- Sprint 1 (models and migrations)
