---
title: "feat: dual-key model for Agents & API (bootstrap exchange + long-lived API keys)"
type: feat
created: 2026-04-15
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Encrypted API keys, one-time bootstrap exchange, admin lifecycle UI, bearer API, auditing, docs, and specs are present."
---

# Agents & API: Dual-Key Security Model

## Goal

Introduce a true two-key model:

1. `API Key` for direct API usage (long-lived, default no expiration)
2. `Agent Bootstrap Key` (short-lived, default 1 hour, one-time use) that exchanges into a new API key for agent workflows

Also clean up the admin UX under a single `Agents & API` area so the flows are obvious and visually consistent.

## Context

Current implementation uses one key type (`Railspress::ApiKey`) for both direct API access and agent setup instructions. This is simpler, but it means users paste a long-lived bearer key directly into agent instructions.

Desired model is safer:

- bootstrap secret is short-lived and one-time
- final API key is minted only at exchange time
- agent instructions can embed bootstrap token without directly exposing a long-lived API key

Existing constraints to preserve:

- Active Record Encryption for key secret material
- Rails-native controllers/routes under engine namespaces
- Admin actor model: any signed-in Railspress actor can manage keys
- Current `Agents & API` sidebar destination remains a single nav entry

## Scope Boundaries

In scope:

- Add a new bootstrap-key persistence model/table
- Add unauthenticated exchange endpoint guarded by bootstrap token auth
- Keep API-key auth unchanged for normal `/api/v1/*` resources
- Update admin UX/copy to clearly separate API Keys vs Agent Bootstrap Keys
- Update user-facing docs in `docs/api/`
- Request/model specs for the full lifecycle

Out of scope (for this plan):

- Scopes/permissions matrix per key
- OAuth or external identity providers for API
- Agent-side CLI distribution/install flows
- Usage logs dashboard beyond core fields persisted on key records

## Key Technical Decisions

1. Keep API keys as first-class long-lived credentials
- `Railspress::ApiKey` remains the bearer credential for all `/api/v1/*` content endpoints.
- API key creation default changes to no expiry (user can optionally set one).

2. Add a separate bootstrap key model (not a polymorphic type flag on `ApiKey`)
- Create `Railspress::AgentBootstrapKey` table/model with its own token format and lifecycle.
- Rationale: cleaner auth parsing, simpler invariants, easier auditing.

3. One-time exchange mints a brand new API key
- Endpoint: `POST /railspress/api/v1/agent_keys/exchange`.
- Input auth: bootstrap token (`Authorization: Bearer rpb_...`).
- Success: returns newly minted API key plaintext once and marks bootstrap key as used.
- Replay is rejected.

4. Distinct token prefixes
- API key token format stays: `rp_<env>_<prefix>_<secret>`.
- Bootstrap token format: `rpb_<env>_<prefix>_<secret>`.
- Prevents accidental cross-use and keeps parser logic explicit.

5. Bootstrap defaults are strict
- Expires in 1 hour by default.
- One-time use enforced (`used_at` / `exchanged_api_key_id`).
- Revocable before use from admin.

6. Agent instructions split remains
- Generic instructions: no secrets.
- Tokenized reveal instructions: include bootstrap token and exchange command.
- Include optional local storage (`~/.railspress_token`, `chmod 600`).

## Data Model Plan

### A. Keep `railspress_api_keys` as direct API credentials

- No new key type enum needed.
- Change API-key creation defaults (controller-level behavior): `expires_at` defaults to `nil` unless user sets it.

### B. Add `railspress_agent_bootstrap_keys`

Proposed columns:

- `name` (string, required)
- `token_prefix` (string, required, indexed)
- `token_digest` (string, required, unique)
- `secret_ciphertext` (text, required, encrypted)
- `expires_at` (datetime, required)
- `used_at` (datetime)
- `used_ip` (string)
- `revoked_at` (datetime)
- `revoke_reason` (string)
- `exchanged_api_key_id` (bigint, indexed)
- `owner_type`, `owner_id` (polymorphic, optional)
- `created_by_type`, `created_by_id` (polymorphic, optional)
- `revoked_by_type`, `revoked_by_id` (polymorphic, optional)
- `global_uuid` (uuid, required, unique, DB default)
- Rails timestamps

Model behavior:

- `issue!` (default `expires_at: 1.hour.from_now`)
- `authenticate` (active + digest constant-time compare)
- `exchange!` transaction:
  - ensure active and unused
  - issue new `ApiKey`
  - set `used_at`, `used_ip`, `exchanged_api_key_id`
  - return `[api_key, plain_api_token]`
- `revoke!`

## API Contract Plan

### 1. New exchange endpoint

`POST /railspress/api/v1/agent_keys/exchange`

Auth:

- `Authorization: Bearer rpb_...`

Response `201`:

```json
{
  "data": {
    "api_key": {
      "token": "rp_...",
      "name": "Agent session key",
      "expires_at": null
    },
    "bootstrap": {
      "id": "...",
      "used_at": "..."
    }
  }
}
```

Failure modes:

- `401` invalid/malformed bootstrap token
- `401` expired/revoked/used bootstrap token
- `422` exchange cannot mint API key (validation issue)

### 2. Existing API endpoints unchanged

- `GET /api/v1/prime`, posts/categories/tags/imports continue to require API key (`rp_...`).
- `Prime` payload can include a small `auth_modes` hint to document bootstrap-exchange support.

## Admin UX Plan ("make it look good")

Create a clear, single destination page under current sidebar item `Agents & API`:

1. Section: API Keys
- Direct API keys list + create/rotate/revoke
- Copy and labels consistently use “API Key”
- Helper text clarifies default no-expiration

2. Section: Agent Bootstrap Keys
- Bootstrap key list + create/revoke (rotate optional via create-new)
- Display status chips: active/used/expired/revoked
- One-time reveal shows bootstrap token and exchange-ready instructions

3. Instruction UX
- Keep separate generic and tokenized instruction blocks.
- Provide copy buttons for:
  - quick start
  - full instructions
  - raw token
- Keep typography/spacing/button style aligned with existing `rp-` form/table components.

4. Naming consistency
- Stop calling API keys “agent keys”.
- Use exact terms in UI:
  - `API Key`
  - `Agent Bootstrap Key`

## Implementation Phases

### Phase 1: Persistence + Models

- Add migration for `railspress_agent_bootstrap_keys`
- Add `Railspress::AgentBootstrapKey` model with encrypted secret + digest auth
- Add associations from bootstrap -> exchanged API key
- Add model specs for issue/authenticate/exchange/revoke invariants

### Phase 2: Exchange API Endpoint

- Add `Railspress::Api::V1::AgentKeys::ExchangesController` (or `AgentKeyExchangesController`)
- Add route in `api/v1` namespace
- Add bootstrap token authentication path isolated from standard API-key auth
- Add request specs for success + replay + expired + revoked

### Phase 3: Admin Controllers/Views

- Add `Admin::AgentBootstrapKeysController`
  - `index/new/create/revoke`
- Keep `Admin::ApiKeysController` focused on API keys
- Update shared `Agents & API` page composition and improve visual hierarchy
- Ensure one-time reveal page for bootstrap tokens mirrors API reveal polish

### Phase 4: Instruction Templates

- Update instruction generators:
  - generic instructions describe bootstrap exchange
  - tokenized instructions include bootstrap token and exchange command
  - optional local file persistence commands for API key
- Ensure examples are shell-safe and copy/paste friendly

### Phase 5: Docs

Update:

- `docs/api/README.md`
- `docs/api/authentication.md`
- `docs/api/prime.md`

Add (if needed):

- `docs/api/agent_bootstrap_keys.md` (admin + exchange flow)

Docs must explicitly cover:

- two token types and when to use each
- bootstrap 1-hour + one-time semantics
- API key default expiry behavior
- revoke/rotate guidance

### Phase 6: Regression + Fit/Finish

- Full request spec pass for API auth-critical endpoints
- Admin request/system sanity for both key lifecycles
- Verify dummy app UX flow end-to-end:
  - create bootstrap key
  - exchange for API key
  - call `POST /posts`

## Test Plan

Model specs:

- `Railspress::ApiKey` defaults/behavior after expiry-default change
- `Railspress::AgentBootstrapKey` issue/auth/active/used/revoked/exchange

Request specs:

- exchange endpoint success + replay rejection
- exchange with expired/revoked/bootstrap-invalid token
- normal API endpoints reject bootstrap token
- normal API endpoints still accept API key

Admin specs:

- create/revoke bootstrap key
- one-time bootstrap reveal content
- API key screens keep working with revised copy/defaults

## Migration and Rollout Notes

- Backward compatibility: existing API keys remain valid.
- No breaking change to existing `rp_*` token parser.
- New bootstrap flow is additive; teams can adopt incrementally.
- UI copy updates should avoid implying old keys are invalid.

## Open Questions

1. API key name on exchange
- Default to bootstrap key name with suffix (e.g. `"<name> (exchanged)"`) vs explicit field captured during bootstrap creation.

2. API key expiry when created by exchange
- Default `nil` (long-lived) vs configurable at bootstrap creation (`api_key_expires_at`).

3. Bootstrap rotate UX
- Keep as create+revoke only (simpler), or add explicit rotate action for parity.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/data_layer/schema_conventions.md`
- `docs/conventions/domain/authentication.md`
- `docs/conventions/domain/route_naming.md`
- `docs/conventions/frontend/forms.md`
- `docs/conventions/frontend/selection_and_navigation.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`

## System Docs and Existing Implementation Inputs

- `plans/api-support/api-v1-foundation-and-posts.md`
- `docs/api/README.md`
- `docs/api/authentication.md`
- `app/models/railspress/api_key.rb`
- `app/controllers/railspress/api/v1/base_controller.rb`
- `app/controllers/railspress/api/v1/prime_controller.rb`
- `app/controllers/railspress/admin/api_keys_controller.rb`
