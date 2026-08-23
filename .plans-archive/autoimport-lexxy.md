---
title: Auto-import Lexxy from Engine
type: feat
created: 2026-03-25
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "The engine pins and imports Lexxy, dummy host duplication is removed, and generator/importmap coverage is present."
---

# Auto-import Lexxy from Engine

## Overview

Host apps currently need to manually pin and import Lexxy (the rich text editor) in their importmap and application.js. Since Lexxy is a hard dependency in the gemspec and is always installed, the engine should handle this automatically — eliminating a setup step that every host app has to do.

## Problem Statement

- Every host app must add `pin "lexxy", to: "lexxy.js"` to `config/importmap.rb`
- Every host app must add `import "lexxy"` to `application.js`
- Forgetting either step breaks the admin rich text editor with no helpful error
- Lexxy is a required gem dependency — it's always present, so there's no reason to make the host app wire it up

## Proposed Solution

Two changes, both in the engine:

### 1. Pin Lexxy in engine importmap

**File:** `config/importmap.rb`

Add:

```ruby
pin "lexxy", to: "lexxy.js"
```

This auto-propagates to host apps via the `railspress.importmap` initializer in `engine.rb` (which already appends the engine's importmap paths). No host app changes needed.

### 2. Import Lexxy from engine JS entry point

**File:** `app/javascript/railspress/index.js`

Add at the top (before the Turbo import):

```js
import "lexxy"
```

Since `import "railspress"` is already required for Stimulus controllers, Lexxy comes along for the ride.

## Files to Change

| File | Change |
|------|--------|
| `config/importmap.rb` | Add `pin "lexxy", to: "lexxy.js"` |
| `app/javascript/railspress/index.js` | Add `import "lexxy"` |

## Docs to Update

| File | Change |
|------|--------|
| `docs/CONFIGURING.md` | Remove the "Host app importmap" bullet under the Lexxy section (~line 472). Simplify to say the engine handles Lexxy automatically. |
| `docs/CONFIGURING.md` | Update the "Keeping Lexxy Updated" section — host apps still control the gem version via Gemfile, but no longer need an importmap pin. |
| `docs/README.md` | Check for any setup steps mentioning Lexxy importmap pin and remove them. |
| `docs/TROUBLESHOOTING.md` | Check for Lexxy-related troubleshooting and update if needed. |

## Dummy App Cleanup

Remove the now-redundant lines from the dummy app to prove host apps no longer need them:

| File | Change |
|------|--------|
| `spec/dummy/config/importmap.rb` | Remove `pin "lexxy", to: "lexxy.js"` |
| `spec/dummy/app/javascript/application.js` | Remove `import "lexxy"` |

## Testing

### 1. Verify importmap resolution

After removing the dummy app's Lexxy pin, confirm the engine's pin takes over:

```bash
cd spec/dummy && bundle exec rails importmap:audit 2>/dev/null; bundle exec rails runner "puts Rails.application.importmap.to_json" | grep lexxy
```

The `"lexxy"` pin should still resolve to `"lexxy.js"` via the engine's importmap.

### 2. Run existing specs

```bash
bundle exec rspec
```

All existing specs should pass — nothing about Lexxy behavior changes, only where the pin/import lives.

### 3. Manual smoke test

```bash
cd spec/dummy && bin/rails server
```

- Navigate to `/railspress/admin/posts/new`
- Confirm the Lexxy rich text editor loads in the content field
- Create/edit a post with rich text content
- Confirm no JS console errors related to Lexxy or importmap resolution

## Edge Cases

- **Host app that pins Lexxy independently:** No conflict — importmap-rails uses last-wins for duplicate pins, so the host app's pin would override the engine's. This is fine and expected.
- **API-only app using Railspress models:** They wouldn't import `"railspress"` in JS at all, so the Lexxy import never executes. The gem is still in the bundle but the JS is never loaded. No impact.
