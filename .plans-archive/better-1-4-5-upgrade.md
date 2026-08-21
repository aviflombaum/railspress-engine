---
title: "Make the 1.4.5 Auth/Mount Upgrade Self-Diagnosing"
type: fix
created: 2026-08-21
created_by: Avi Flombaum
status: superseded
superseded: 2026-08-21
superseded_by: better-1-4-5-upgrade-evaluation.md
archived: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 65%
sweep_notes: "Diagnostics and guidance shipped, but boot-time detection and the compatibility constraint were deferred or declined by the implemented evaluation plan."
---

# Make the 1.4.5 Auth/Mount Upgrade Self-Diagnosing

## Overview

The 1.4.5 admin/API authentication boundary change is correct and fully documented, but it is
invisible at runtime. A host that upgrades without reading `docs/UPGRADING.md` end-to-end gets no
signal from the engine — not at boot, not at request time — that its configuration is now wrong.
Two of the three resulting failure modes fail *open* (public admin UI) or fail *misleadingly*
(HTTP 404/200 on an authenticated API endpoint) rather than loudly.

This plan adds boot-time detection for the three specific misconfigurations 1.4.5 can produce,
makes existing deprecations visible to a developer who is not tailing `development.log`, and
proposes one genuine backward-compatibility shim so hosts that mount behind a constraint keep
working instead of silently losing their API.

## Problem Statement

RailsPress 1.4.5 moved admin protection from "whatever the host wrapped the mount in" to
"`config.admin_authentication_method`, invoked by the engine." The engine cannot tell, on its own,
whether a host completed that move. Today it does not try.

### Evidence: two real host applications

**`avi.nyc` (avinyc-rails)** — upgraded to 1.4.5, initializer left at pre-1.4.5 shape.

The host had the engine mounted behind a session-cookie route constraint:

```ruby
class AdminConstraint
  def self.matches?(request)
    session_id = request.cookie_jar.signed[:session_id]
    return false if session_id.blank?
    Session.includes(:user).find_by(id: session_id)&.user&.admin?
  end
end

constraints AdminConstraint do
  mount Railspress::Engine => "/railspress"
end
```

Failure mode 1 — the API was unreachable. A correct bearer token against a correct URL returned
Rails' routing error page, because the constraint runs before any controller:

```
GET /railspress/api/v1/prime  →  ActionController::RoutingError
                                 "No route matches [GET] /railspress/api/v1/prime"
```

No mention of RailsPress, auth, or the constraint. The engine's own API docs describe this
symptom (`docs/api/authentication.md`, added in 1.3.2), but only if you already suspect the cause.

Failure mode 2 — removing the constraint, exactly as `docs/UPGRADING.md` instructs, published the
admin UI to the internet. The host's `ApplicationController` calls `allow_unauthenticated_access`,
so there was no inherited callback to fall back on, and `admin_authentication_method` was unset:

```
GET /railspress/admin           →  200 OK   (dashboard, no session)
GET /railspress/admin/api_keys  →  200 OK   (API key management, no session)
```

The engine booted clean. `config.enable_api` was set, so
`ActiveRecordEncryptionConfiguration#validate!` ran and passed — the one boot-time check that
exists is unrelated to this class of mistake.

Failure mode 3 — the deprecated setting was in use and warned, but invisibly. The initializer
still had `config.current_api_actor_proc`. The deprecator fires correctly:

```
DEPRECATION WARNING: config.current_api_actor_proc is deprecated and will be removed in
RailsPress 2.0; use config.current_admin_proc instead.
```

It appeared exactly once, in a 78 MB `log/development.log`. `Rails.application.deprecators[:railspress].behavior`
resolves to the app default, which is `:log` in development and typically `:silence`/`:log` in
production. A developer running `bin/dev` and watching the terminal never sees it.

**`grace-berman-app`** — still on 1.2.1, and will hit all of the above plus one more when it
upgrades. Current state:

```ruby
# config/routes.rb
constraints AdminConstraint do
  mount Railspress::Engine => "/railspress"
end
get "railspress(*path)", to: "sessions#new"   # catch-all fallback
```

```ruby
# config/initializers/railspress.rb — no admin_authentication_method, no admin_auth_concern
config.enable_authors
config.enable_post_images
config.enable_focal_points
config.enable_cms
config.inline_editing_check = ->(_context) { Current.user.present? }
```

Notes specific to this host:

- It does **not** call `config.enable_api`, so the encryption validator stays silent and the
  1.4.5 upgrade appears to be a no-op. The mount constraint keeps working. The trap is deferred:
  the day someone adds `config.enable_api`, the API 404s with no explanation.
- Worse than a 404 — the catch-all `get "railspress(*path)", to: "sessions#new"` swallows the
  constraint miss and returns **200 OK with an HTML login page** for every
  `/railspress/api/v1/*` request. An API client sees a success status and HTML where JSON was
  expected. This is the least debuggable variant of the failure.
- Its `ApplicationController` includes an `Authentication` concern with a global
  `before_action :require_authentication` and no `allow_unauthenticated_access`. So after
  upgrading, inherited protection *does* cover the RailsPress admin, and leaving
  `admin_authentication_method` unset is legitimate — but only by accident, and only at
  "any logged-in user" granularity rather than the admin check the constraint implied.
  Nothing tells the operator which of the two situations they are in.
- Jumping 1.2.1 → 1.4.5 also crosses the 1.4.3 `search`/`page`/`per_page_count` → `rp_*`
  deprecations. Confirmed unused in this host, but the same invisibility applies.

### Root cause

The engine has exactly one boot-time configuration check
(`Railspress::ActiveRecordEncryptionConfiguration#validate!`, gated on `api_enabled?`) and one
config validation (`Configuration#validate!`, which only checks `inline_editing_check` against
`cms_enabled`). Neither covers the mount/auth boundary that 1.4.5 actually changed.

All the correct guidance exists in `docs/UPGRADING.md`, `docs/CONFIGURING.md`, and the install
generator's post-install message — but the generator's message only prints when someone runs
`rails g railspress:install`. The realistic upgrade path is `bundle update railspress-engine`,
which prints nothing.

## Goals

1. A host that upgrades to 1.4.5 and is now misconfigured finds out at boot, from a message that
   names the exact setting and the exact file to change.
2. A host that mounts behind a route constraint keeps a working API instead of silently losing it.
3. Deprecation warnings from RailsPress reach a developer who is watching a terminal, not just a
   log file, without hijacking the host's deprecation policy.
4. No new failure mode where a correctly-configured host is nagged on every boot.

## Non-Goals

- Changing the 1.4.5 auth architecture. Inheriting the host `ApplicationController` for browser
  controllers and isolating API controllers on `ActionController::API` is the right design.
- Auto-editing host `routes.rb` or initializers outside the install generator.
- Guaranteeing that a host's `admin_authentication_method` actually authorizes correctly. The
  engine can verify the method exists and is invoked; it cannot verify the host's policy.

## Proposed Work

### 1. Detect a constrained mount at boot

The mount shape is introspectable and the check is cheap. Verified against both cases:

```ruby
# plain mount
route.app.constraints  # => []

# constraints AdminConstraint do ... end
route.app.constraints  # => [AdminConstraint]
```

For a route whose `app.app` is `Railspress::Engine`, a non-empty `app.constraints` means every
request to the engine — API included — is filtered before RailsPress auth runs.

Add `Railspress::MountConfiguration` with a `validate!` invoked from a new engine initializer
after routes are loaded. When constraints are present:

- If `api_enabled?` — raise `Railspress::ConfigurationError`. The API is definitionally broken;
  this is not a warning-level condition. Message names the constraint class, states that
  `/railspress/api/*` will never reach bearer authentication, and points at both remedies
  (plain mount + `admin_authentication_method`, or `Railspress::MountConstraint` from item 3).
- If API is disabled — `Railspress.deprecator.warn` describing the latent trap, so
  `grace-berman-app` learns about it on upgrade rather than months later.

Route loading is lazy; hook this on `app.reloader.to_prepare` or an `after_initialize` that
touches `Rails.application.routes.routes`, and guard against hosts that mount the engine more
than once or not at all.

### 2. Detect an unprotected admin at boot

Condition to detect: `admin_authentication_method` blank **and** `admin_auth_concern` blank
**and** no inherited halting `before_action` on `Railspress::Admin::BaseController`.

The third clause is what separates `avi.nyc` (genuinely open) from `grace-berman-app`
(protected by an inherited `require_authentication`). Inspect
`Railspress::Admin::BaseController._process_action_callbacks`, subtract the engine's own
callbacks (`authenticate_railspress_admin!`), and check whether anything the host contributed
remains. Run inside `to_prepare` so it survives reloads and sees the final callback chain.

Behavior: log a prominent warning, not a raise — a host may protect the admin by means the engine
cannot see (upstream middleware, Rack::Auth, a reverse proxy). Wording should be unambiguous
about what was observed: "RailsPress admin controllers have no host authentication callback and
`config.admin_authentication_method` is unset. `/railspress/admin` is reachable without a session."

Consider gating the raise-vs-warn decision on `Rails.env.production?` — production is where
failing open matters, and a boot failure there is preferable to a public API key management page.

### 3. Backward compatibility: a constraint that lets the API through

This is the answer to "can we maintain backward compatibility instead of only warning." Ship a
supported constraint wrapper so hosts that legitimately want a route-level gate keep one, without
severing the API:

```ruby
# config/routes.rb
constraints Railspress::MountConstraint.new(AdminConstraint) do
  mount Railspress::Engine => "/railspress"
end
```

`MountConstraint#matches?` returns `true` unconditionally for paths under the engine's
`api/v1` prefix (which carry their own bearer authentication) and delegates to the wrapped
constraint for everything else. This converts today's silent breakage into a one-line migration
that preserves the host's existing security posture, and gives the item-1 error message a concrete
remedy to point at for hosts unwilling to move auth into the initializer.

### 4. Make RailsPress deprecations visible on upgrade

Keep `app.deprecators[:railspress]` registered — hosts must retain control. Add a boot-time
summary that does not depend on deprecation behavior: collect deprecated-setting usage during
`Railspress.configure`, then emit one consolidated notice via `Rails.logger.warn` **and** `$stderr`
in development/test when the list is non-empty:

```
[RailsPress 1.4.5] 1 deprecated setting in config/initializers/railspress.rb:
  config.current_api_actor_proc → config.current_admin_proc
See docs/UPGRADING.md#upgrading-to-145
```

One block, at boot, naming the file. Silent in production unless the host opted into deprecation
output. This is what would have caught `avi.nyc` before anything else on this list.

### 5. `railspress:doctor` rake task

An on-demand version of items 1, 2, and 4 that prints the resolved configuration and its verdict —
mount path and constraints, admin auth strategy and whether the named method resolves, current-admin
strategy, API enabled + encryption credential presence, deprecated settings in use, engine version.

Give the upgrade path something to run, and give `docs/UPGRADING.md` and
`docs/TROUBLESHOOTING.md` a single command to recommend. Add it to the post-install and
post-upgrade generator messages.

### 6. Documentation and installer follow-ups

- Move `admin_authentication_method` / `current_admin_method` out of the `=== API (opt-in) ===`
  block in `lib/generators/railspress/install/templates/initializer.rb`. They govern the admin UI
  and matter to every host, including the many that never enable the API. Their current placement
  implies they are API-only settings.
- `docs/UPGRADING.md` §1.4.5: lead with the mount/auth change rather than the encryption
  prerequisite. The encryption change raises loudly on its own; the auth change is the one that
  fails silently and therefore needs the prominence.
- Add the `grace-berman-app` catch-all shape (`get "railspress(*path)"` after a constrained mount)
  to `docs/TROUBLESHOOTING.md` as a named symptom: HTML 200 responses on API endpoints.

## Sequencing

| Step | Work | Rationale |
|------|------|-----------|
| 1 | Item 4 (deprecation summary) | Smallest change, catches the most common upgrade mistake |
| 2 | Item 1 (constrained mount detection) | Highest-severity silent failure; introspection already verified |
| 3 | Item 3 (`MountConstraint`) | Gives item 1's error a migration path instead of only a diagnosis |
| 4 | Item 2 (unprotected admin detection) | Needs the most care to avoid false positives |
| 5 | Items 5–6 (`doctor`, docs, template) | Consolidation once behavior is settled |

Items 1–4 are host-visible behavior changes and warrant a 1.4.6 release with its own
`Upgrade Notes` section. Item 1's raise is arguably breaking for a host currently running a
constrained mount with the API enabled — but that host's API is already non-functional, so the
raise converts a silent outage into a boot-time error with instructions.

## Verification

- Dummy app request specs for each shape: plain mount + configured auth (clean boot, no output);
  constrained mount + API enabled (raises, message names the constraint class); constrained mount +
  API disabled (deprecation warning); no auth method + no inherited callback (warning); no auth
  method + inherited callback present (silent — this is the `grace-berman-app` case and must not
  produce a false positive).
- `MountConstraint` request specs: `/railspress/api/v1/prime` passes through with a bearer token
  while `/railspress/admin` is still gated by the wrapped constraint.
- Rehearse the real upgrade against a local checkout of `grace-berman-app` (1.2.1 → 1.4.5) and
  confirm the emitted messages are sufficient to fix the app without opening `docs/UPGRADING.md`.
