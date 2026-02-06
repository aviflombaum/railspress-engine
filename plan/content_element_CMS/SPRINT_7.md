# Sprint 7: Inline Editing (Future - Stimulus/Turbo)

## Goal

Enable authenticated admins to right-click any CMS-backed content on the live site and edit it inline via a popup editor. Changes submit through Turbo Frames and immediately update the page.

**Status**: FUTURE - This sprint is planned but not part of the initial implementation. It will be built after the admin backend is solid and tested.

## Architecture

Based on `innovent-rails/.ai/inline_cms_editor_plan.md` and the working implementation:

1. **CMS Helper wraps content** with a Stimulus controller div when admin is authenticated
2. **Right-click** opens a positioned context menu with a Turbo Frame
3. **Turbo Frame lazily loads** an inline edit form from the admin controller
4. **Form submission** updates via Turbo Stream, immediately refreshing the content
5. **Auto-versioning** fires on save, maintaining the audit trail

## Tasks

### 7.1 Stimulus Controller

**File**: `app/javascript/controllers/railspress/cms-inline-editor_controller.js`

Port from `innovent-rails/app/javascript/controllers/cms-inline-editor_controller.js`:
- Targets: menu, frame, backdrop, display
- Values: inlinePath, updatePath, frameId, formFrameId, elementId
- Actions: open (contextmenu), close (escape/outside click), handleSubmitEnd
- Lazy-loads Turbo Frame on first open
- Smart positioning within viewport bounds

### 7.2 Inline Form Partials

**Files**:
- `app/views/railspress/admin/content_elements/_inline_form.html.erb`
- `app/views/railspress/admin/content_elements/_inline_form_frame.html.erb`

Lightweight form with just the text_content field, wrapped in a Turbo Frame.

### 7.3 Update CMS Helper for Inline Wrapping

**File**: Update `app/helpers/railspress/cms_helper.rb`

Add `inline_wrapper_for` method that wraps content with:
- `data-controller="cms-inline-editor"`
- Data values for paths and IDs
- Turbo Frame for content display
- Hidden context menu markup
- Hidden backdrop

Gate behind admin authentication check.

### 7.4 Add Inline Action to Controller

**File**: Update `app/controllers/railspress/admin/content_elements_controller.rb`

Add `inline` action that renders the inline form partial within a Turbo Frame.
Update `update` action with `turbo_stream` response for inline updates.

### 7.5 CSS for Inline Editor

**File**: Update `app/assets/stylesheets/railspress/admin.css`

Add styles for:
- `.rp-inline-editor` - context menu panel
- `.rp-inline-editor__backdrop` - overlay
- `.rp-inline-editor__form` - compact form
- Positioning and z-index

### 7.6 Authentication Integration

The inline editor requires knowing if the current user is an admin. The host app needs to provide:
```ruby
# In host app's ApplicationController or config
Railspress.configure do |config|
  config.admin_check = ->(request) { Current.user&.admin? }
end
```

## Acceptance Criteria

- [ ] Right-click on CMS content opens inline editor (when admin)
- [ ] Inline form loads via Turbo Frame
- [ ] Saving updates content immediately without page reload
- [ ] Version is created on inline save
- [ ] Escape/outside click closes editor
- [ ] No editor markup rendered for non-admin users
- [ ] Works in all environments (not dev-only)

## Dependencies

- Sprint 1-6 (complete CMS backend)
- Host app authentication integration
