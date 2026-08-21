---
title: "feat: API support foundation with encrypted keys and Posts v1"
type: feat
created: 2026-04-15
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Versioned bearer-authenticated API foundation, Post CRUD, pagination, encryption, documentation, and specs are present."
---

# API Support Foundation with Encrypted Keys and Posts v1

## Goal

Add first-class API support to Railspress so host-application users can programmatically CRUD Railspress resources, starting with Posts, using named, rotatable API keys stored with Active Record Encryption.

## Context

Railspress currently exposes only admin HTML controllers/routes and has no API auth surface. The first API iteration should:

- Use pragmatic path versioning (`/api/v1`) under the mounted engine path
- Follow Rails controller/resource patterns rather than introducing a separate framework
- Provide secure key lifecycle primitives (create, list metadata, rotate, revoke)
- Treat keys as full-access to the currently exposed API surface in v1 (no scope matrix yet)
- Ship end-user docs in `docs/api/` as part of the feature, not as a follow-up

Constraints from existing docs/code:

- Engine route namespace and mount pattern in [docs/CONFIGURING.md](../../docs/CONFIGURING.md)
- Post model behavior and fields in [docs/BLOGGING.md](../../docs/BLOGGING.md) and [docs/README.md](../../docs/README.md)
- Upgrade/migration workflow in [docs/UPGRADING.md](../../docs/UPGRADING.md)
- Existing `Railspress.configure` hook style (`current_author_method`, `current_author_proc`) should be mirrored for API integration points

## Scope Boundaries

In scope for this plan:

- API foundation (`api/v1` routing, base controller, error envelope, auth middleware logic)
- API key persistence and lifecycle with Active Record Encryption-backed secret storage
- Admin-facing key management UX/routes for generation/rotation/revocation
- Posts API resource only (index/show/create/update/destroy)
- End-user API docs in `docs/api/`
- Request/model specs for all above

Out of scope for this initial rollout:

- Categories/tags/entities/content elements API resources
- OAuth2 provider setup (Doorkeeper) and JWT flows
- Per-account multi-tenancy model changes beyond optional owner scoping hook
- API write support for binary upload flows (ActiveStorage direct uploads)
- API webhooks/event subscriptions

## Key Technical Decisions

1. Versioned path namespace from day one
- Implement under `namespace :api do; namespace :v1 do ... end end` in engine routes.
- Avoid header-based version negotiation for v1.

2. Rails-native controllers and routing
- Use `ActionController::API` base controller for API namespace.
- Keep resource controllers conventional and model-backed.

3. Dual token persistence strategy: encrypted secret + digest lookup
- Store key secret material encrypted via `encrypts` on `Railspress::ApiKey` to satisfy at-rest encryption requirement.
- Store `token_digest` (HMAC/SHA-256) for authentication lookup and constant-time verification.
- Never return stored secret after create/rotate response.

4. Prefix + digest authentication
- Token format: `rp_{env}_{prefix}_{secret}` (exact prefix shape finalized in Phase 1).
- Lookup candidate key by indexed prefix, verify digest in constant time, then enforce active constraints (`revoked_at`, `expires_at`).

5. Key lifecycle modeled as records, not mutable columns
- Rotate by creating a new key row and revoking prior row in one transaction.
- Preserve auditability via `rotated_from_id`, timestamps, and last-used metadata.

6. Feature gating and host integration hooks
- Introduce `config.enable_api` toggle (default off) for safe adoption.
- Add host-facing proc/method hook for key owner resolution where needed (parallel to existing author hooks).

7. Documentation as product surface
- Treat `docs/api/` as required deliverable with auth, errors, pagination, and Posts endpoint references.

8. Key ownership and rotation policy
- On key creation, persist the current logged-in Railspress user as key owner metadata.
- Any logged-in Railspress user can rotate keys (not owner-restricted).
- Record actor and timestamp for create/rotate/revoke operations for auditability.

9. Authorization model for v1 keys
- No per-key scope granularity in v1.
- Any valid, active key can access all API resources that Railspress exposes.
- Resource exposure is the security boundary for v1.

10. Secret retention policy for v1
- Retain encrypted secret material (`secret_ciphertext`) for the lifetime of key records.
- Do not expose stored secret material via UI or API after create/rotate.
- Preserve rotated/revoked key records for operational/audit tracking.

## Plan

### Phase 0: API Architecture and Contract Draft

1. Define API conventions doc (internal plan artifact) for:
- Envelope format (success/errors)
- HTTP status usage
- Pagination params and metadata
- Filtering/sorting conventions for Posts
- Idempotency expectations for create/update

2. Define final route map:
- `POST /api/v1/posts`
- `GET /api/v1/posts`
- `GET /api/v1/posts/:id`
- `PATCH /api/v1/posts/:id`
- `DELETE /api/v1/posts/:id`
- key lifecycle operations are admin-only in v1 (no `/api/v1/api_keys` endpoints)

3. Identify JSON contract for Posts v1:
- Required fields: `title`
- Optional fields: `slug`, `content`, `status`, `published_at`, `category_id`, `meta_title`, `meta_description`, `tag_list`, `reading_time`
- Exclude attachments for v1 writes

Deliverable:
- Finalized endpoint/response contract embedded in this plan and copied into `docs/api/posts.md` during docs phase.

### Phase 1: Encrypted API Key Foundation

1. Add new data model + migration(s):
- `railspress_api_keys` table with at minimum:
  - `name` (string, required)
  - `token_prefix` (string, required, indexed)
  - `token_digest` (string, required, unique index)
  - `secret_ciphertext` (text, required; backing column for `encrypts :secret`)
  - `expires_at` (datetime)
  - `last_used_at` (datetime)
  - `last_used_ip` (string)
  - `revoked_at` (datetime)
  - `revoke_reason` (string)
  - `rotated_from_id` (integer, indexed)
  - polymorphic owner columns (`owner_type`, `owner_id`) if owner scoping is enabled
  - optional external id `global_uuid` (uuid, unique index)

2. Implement `Railspress::ApiKey` model:
- `encrypts :secret`
- validations for name/prefix/digest uniqueness and lengths
- scopes: `active`, `revoked`, `expired`
- lifecycle methods: `.issue!`, `#rotate!`, `#revoke!`, `.authenticate(raw_token)`
- constant-time compare for digest verification

3. Implement token generation service:
- `Railspress::ApiKeys::Issuer`
- returns `[api_key_record, plaintext_token]`
- writes encrypted secret + digest atomically

4. Implement feature flags/config:
- `config.enable_api`
- optional `config.current_api_owner_method` / `config.current_api_owner_proc`

Deliverable:
- Fully testable key issuance + authentication primitives independent of Posts endpoints.

### Phase 2: Key Management Surface (User-Facing in Product)

1. Add key management controller(s) and routes (initially under admin scope):
- `GET /admin/api_keys` (list metadata only)
- `POST /admin/api_keys` (create; returns plaintext once)
- `POST /admin/api_keys/:id/rotate` (rotate; returns plaintext once)
- `POST /admin/api_keys/:id/revoke` (revoke)

2. Add minimal admin UI pages/partials:
- key list (name, prefix, created_at, last_used_at, status)
- create form (name, optional expiry)
- one-time reveal panel after create/rotate

3. Enforce ownership/authorization boundaries:
- key creation requires an authenticated Railspress user
- ownership metadata is always recorded as the creator at issuance time
- rotation is allowed for any authenticated Railspress user (shared operational model)
- every lifecycle action stores actor metadata for traceability

Deliverable:
- Human operators can self-serve key lifecycle before API resource rollout.

### Phase 3: API v1 Base Stack

1. Add API base controller namespace:
- `Railspress::Api::V1::BaseController < ActionController::API`
- bearer token auth in `before_action`
- common render helpers (`render_error`, pagination helpers)

2. Add centralized error handling for:
- auth failures (`401`)
- forbidden access (`403`)
- validation errors (`422`)
- not found (`404`)

3. Add rate limiting hooks (controller-level `rate_limit`) for sensitive endpoints.

Deliverable:
- Stable API skeleton ready for resource controllers.

### Phase 4: Posts Resource (First CRUD Resource)

1. Add controller + routes:
- `Railspress::Api::V1::PostsController`
- conventional CRUD actions (`index`, `show`, `create`, `update`, `destroy`)

2. Implement strong params aligned with Post model and docs.

3. Serialization:
- Start with explicit hash serializer methods (no extra serialization gem)
- Include core fields and timestamps
- Include category/tag ids as lightweight references

4. Behavior decisions for v1:
- default sorting: newest first
- pagination: page/per (existing model pagination conventions where possible)
- `show`/`update`/`destroy` by numeric id in v1 only (no slug lookup in v1)

5. Authorization/scoping:
- baseline: authenticated key required
- optional owner scoping path documented if `authors_enabled?` maps to owner

Deliverable:
- Complete Posts CRUD API behind API key auth.

### Phase 5: End-User Documentation (`docs/api/`)

1. Create docs set:
- `docs/api/README.md` (overview + quickstart)
- `docs/api/authentication.md` (key lifecycle, bearer format, rotation/revocation)
- `docs/api/errors.md` (error schema and status codes)
- `docs/api/posts.md` (endpoint-by-endpoint examples)

2. Add documentation updates:
- link from `docs/README.md`
- mention migration/install steps in `docs/UPGRADING.md`
- mention config toggles in `docs/CONFIGURING.md`

3. Include copy-paste examples:
- curl examples for create/list/update/delete posts
- explicit create/rotate/revoke examples for keys
- note that v1 keys are full-access for currently exposed resources

Deliverable:
- End-user-facing API docs shipped with feature.

### Phase 6: Test Plan

1. Model specs:
- `Railspress::ApiKey` issuance/authentication/revocation/rotation behavior
- digest + encrypted-secret persistence invariants

2. Request specs (API):
- auth required behavior across endpoints
- posts CRUD success + validation failures + not found
- invalid/revoked/expired key failures

3. Request/system specs (admin key management):
- create/rotate/revoke flows
- one-time plaintext reveal behavior

4. Regression checks:
- existing admin posts workflows remain unaffected
- engine migration install path still clean in dummy app

## Open Questions

1. Owner model strategy
- Resolved: keys store `current_author` (current logged-in Railspress user) as owner metadata at creation.

2. Key management surface
- Resolved: key lifecycle is admin-only for v1; no API key-management endpoints.

3. Scope model
- Resolved: no scopes in v1; valid keys can access all exposed API resources.

4. Rotation authorization policy
- Resolved: any logged-in Railspress user may rotate keys; rotation is not owner-restricted.

5. Post lookup mode
- Resolved: numeric ID only for v1 `show`/`update`/`destroy` endpoints.

6. Secret retention policy
- Resolved: keep encrypted secret material for full key-record lifetime (including rotated/revoked keys) for audit/operational tracking.

## Conventions

Planning and implementation must follow:

- `docs/conventions/architecture/architecture.md`
- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/data_layer/schema_conventions.md`
- `docs/conventions/domain/authentication.md`
- `docs/conventions/domain/route_naming.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`

## System Docs and Research Inputs

- [docs/CONFIGURING.md](../../docs/CONFIGURING.md)
- [docs/BLOGGING.md](../../docs/BLOGGING.md)
- [docs/README.md](../../docs/README.md)
- [docs/UPGRADING.md](../../docs/UPGRADING.md)
- Rails API controllers/routing guidance, Rails Active Record Encryption guidance, and prior option analysis (custom Rails controllers + versioned namespace chosen)
