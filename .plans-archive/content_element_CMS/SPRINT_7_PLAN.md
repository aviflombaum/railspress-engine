---
title: "Right-Click Inline CMS Editor Demo Plan"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "The demo page, right-click editor flow, Turbo frames/streams, permission checks, and supporting UI are present."
---

# Plan: Right-Click Inline CMS Editor for /pages Demo

## Context

The Content Element CMS (Sprints 1-6) is complete with models, controllers, views, helper API, and tests. Sprint 7 was planned but deferred — it adds a right-click inline editor so admins can edit CMS content directly on the live page.

The Innovent Rails app has a working implementation of this feature. We're porting its Stimulus controller, inline form partials, and CMS helper wrapping to the RailsPress engine, adapted from Tailwind to vanilla CSS with `rp-` prefix. The demo page at `/pages` in the dummy app will showcase the feature.

**Key simplification for this demo**: The Innovent version gates inline editing behind `Current.admin_editing_enabled`. For the dummy app demo, we'll always enable it (no auth check needed — the dummy app has no authentication).

## What Already Exists in RailsPress

- **Route**: `get :inline` member route on content_elements (config/routes.rb:12)
- **Controller action**: `inline` action in ContentElementsController (line 75-82) — responds to Turbo Frame requests with `inline_form_frame` partial
- **Update action**: Already handles Turbo Frame responses, replaces `cms_inline_editor_form_<id>` frame (lines 46-51)
- **CMS Helper**: `cms_element` with `html_options:` parameter reserved for inline editing (line 80)
- **Stimulus infrastructure**: importmap, `register()` function, `window.Stimulus` — all wired up in dummy app
- **Missing**: Stimulus controller, inline form partials, CSS, helper wrapper method, demo page integration

## Implementation Steps

### 1. Create Stimulus Controller
**File**: `app/javascript/railspress/controllers/cms_inline_editor_controller.js`

Port from Innovent's `cms-inline-editor_controller.js`. Same logic:
- Targets: menu, frame, backdrop, display
- Values: inlinePath, updatePath, frameId, formFrameId, elementId
- Actions: open (contextmenu), close (escape/outside click/cancel), handleSubmitEnd
- Lazy-loads Turbo Frame on first right-click open
- Smart viewport-aware positioning

Changes from Innovent version:
- No changes to logic needed — it's pure JS, framework-agnostic styling

### 2. Register the Controller
**File**: `app/javascript/railspress/controllers/index.js` (line 21-34)
**File**: `app/javascript/railspress/index.js` (line 22-33, 28-33)

Add `CmsInlineEditorController` to both the import list and registration functions.
Controller identifier: `railspress--cms-inline-editor`

### 3. Create Inline Form Partials
**File**: `app/views/railspress/admin/content_elements/_inline_form.html.erb`

Lightweight form with:
- Metadata header (group name, element name, version number)
- `text_content` textarea
- Link to "Open in admin" (full admin edit page)
- Save / Cancel buttons
- Styled with vanilla CSS (`rp-` prefix), not Tailwind

**File**: `app/views/railspress/admin/content_elements/_inline_form_frame.html.erb`

Turbo Frame wrapper that renders `_inline_form` inside a `turbo_frame_tag` with the correct frame ID.

### 4. Update CMS Helper with Inline Wrapper
**File**: `app/helpers/railspress/cms_helper.rb`

Add three methods (ported from Innovent `cms_helper.rb`):
- `inline_editor_enabled?` — returns true when inline editing is active. For now, always returns `true` in development. Host apps can configure via `Railspress.config`.
- `inline_wrapper_for(content_element, content, html_options)` — wraps content in a div with Stimulus controller data attributes, a Turbo Frame for display, a context menu panel, and a backdrop
- `cms_inline_frame_id(element)` / `cms_inline_form_frame_id(element)` — frame ID helpers

Update `cms_element` to call `inline_wrapper_for` when `inline_editor_enabled?` returns true (matching the Innovent pattern at cms_helper.rb line ~90-97).

### 5. Add Inline Editor CSS
**File**: `app/assets/stylesheets/railspress/admin/components/inline_editor.css`

Styles for:
- `.rp-inline-menu` — fixed positioned context menu panel (white bg, shadow, rounded, z-50)
- `.rp-inline-backdrop` — fixed full-screen semi-transparent overlay (z-40)
- `.rp-inline-meta` — metadata grid in the form
- `.rp-inline-form` — form spacing and textarea styling
- `.rp-inline-actions` — button row (save/cancel)
- Utility: `.hidden` class (display: none)

Import this CSS from the main application.css or ensure it's included via the asset path.

### 6. Update Demo Page to Enable Inline Editing
**File**: `spec/dummy/app/views/pages/index.html.erb`

The `cms_element` calls already exist with blocks. Once the helper detects `inline_editor_enabled?`, they'll automatically get wrapped. No changes needed to the existing `cms_element` calls — the wrapper is transparent.

Add a banner/notice at the top of the page explaining: "Right-click any CMS content to edit it inline."

**File**: `spec/dummy/app/controllers/pages_controller.rb`

No changes needed if `inline_editor_enabled?` defaults to true in development. If we use a config approach, we'd set it here.

### 7. Ensure CSS Loads on Frontend Pages
**File**: `app/assets/stylesheets/railspress/application.css` or similar

The inline editor CSS needs to load on frontend pages (not just admin). Check that the dummy app's layout includes it, or add a `<style>` tag / stylesheet link in the inline wrapper markup itself to be self-contained.

**Decision**: Make the inline editor CSS self-contained — inject minimal styles via the helper's inline wrapper markup (a `<style>` block rendered once per page). This avoids requiring host apps to include engine stylesheets on their frontend.

### 8. Minimal Tests
**File**: `spec/helpers/railspress/cms_helper_spec.rb` (update existing)

Add tests for:
- `cms_element` returns wrapped content when inline editing is enabled
- `cms_element` returns unwrapped content when inline editing is disabled
- Wrapper includes correct Stimulus data attributes
- Frame IDs are generated correctly

**File**: `spec/requests/railspress/admin/content_elements_spec.rb` (update existing)

Add test for:
- `GET :inline` with Turbo-Frame header returns inline form partial

## Files to Create
1. `app/javascript/railspress/controllers/cms_inline_editor_controller.js`
2. `app/views/railspress/admin/content_elements/_inline_form.html.erb`
3. `app/views/railspress/admin/content_elements/_inline_form_frame.html.erb`

## Files to Modify
4. `app/javascript/railspress/controllers/index.js` — register new controller
5. `app/javascript/railspress/index.js` — register new controller
6. `app/helpers/railspress/cms_helper.rb` — add inline wrapper methods
7. `spec/dummy/app/views/pages/index.html.erb` — add instruction banner
8. `spec/helpers/railspress/cms_helper_spec.rb` — add inline wrapper tests
9. `spec/requests/railspress/admin/content_elements_spec.rb` — add inline action test

## Verification

1. `bundle exec rspec` — all tests pass (existing + new inline tests)
2. Start dummy app: `cd spec/dummy && bundle exec rails server -p 3001`
3. Visit `http://127.0.0.1:3001/pages`
4. Right-click any CMS-powered text — context menu should appear
5. Edit text in the form, click Save — page content updates immediately without reload
6. Press Escape or click outside — menu closes
7. Verify version is created in admin: `http://127.0.0.1:3001/railspress/admin/content_elements`
