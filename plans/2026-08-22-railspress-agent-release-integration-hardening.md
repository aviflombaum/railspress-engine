---
title: "Harden and Complete RailsPress Agent Integration"
created_by: Codex
status: complete
created: 2026-08-22
last_reviewed_at: 2026-08-22
last_reviewed_by: Codex
tags:
  - api
  - agents
  - authentication
  - integration
  - security
---

# feat: Harden and Complete RailsPress Agent Integration

## Goal

Make RailsPress Engine a safe, complete server and onboarding surface for the
new `railspress-agent onboard` and `railspress-agent prime` commands. Enforce
one-time bootstrap exchange at the database boundary, make the Agents & API
page recommend the released CLI outside secret-bearing copied instructions,
provide a token-free `RAILSPRESS.md` bridge, stop redisplaying bootstrap
secrets, and verify the entire contract locally and through the agent's live
cross-repository suite.

## Context

The agent implementation at `../railspress-agent` now owns manifest discovery,
trust approval, credential validation, a bounded no-redirect HTTP client,
stdin-only bootstrap exchange, atomic token storage, and `/prime` validation.
The engine already exposes compatible v1 endpoints, but its current UI still
generates direct `curl`/file-write snippets and reconstructs an active bootstrap
secret on every Agents & API index render.

A follow-up review also found that `AgentBootstrapKey#exchange!` checks
`active?` on an in-memory record before its transaction. Two independently
authenticated handles can therefore both mint API keys. The engine must own the
authoritative one-time guarantee; agent-side locking is defense in depth only.

## Benefits

- One bootstrap token can mint at most one API key, including concurrent or
  stale-handle exchanges.
- The generic admin page never reconstructs or redisplays a bootstrap secret.
- Users can discover, install, and verify RailsPress Agent before creating a
  credential.
- A generated, token-free `RAILSPRESS.md` gives the CLI the exact public host,
  mounted API base, and site-scoped token path.
- Secret reveal instructions become shorter and use the audited CLI boundary.
- Engine request specs remain self-contained while the agent owns the consumer
  and live compatibility tests.

## Scope Boundaries

### In scope

- Atomic database claim inside `AgentBootstrapKey#exchange!`.
- Model and request coverage for one-time and stale/concurrent exchange paths.
- Always-visible RailsPress Agent install guidance on Agents & API.
- Copyable token-free `RAILSPRESS.md` generated from engine configuration.
- CLI-first `config check`, `config trust`, `onboard`, `token store`, and
  `prime` instructions where appropriate.
- Removal of generic-page bootstrap plaintext reconstruction.
- README and API documentation updates for the preferred CLI path.
- Engine-owned request/documentation contract specs.
- Cross-repository verification through the sibling agent checkout.

### Out of scope

- Publishing-domain CLI commands such as `posts create` or media upload.
- Making the engine depend on, vendor, or install the agent repository.
- A Git submodule or sibling-checkout requirement for ordinary engine RSpec.
- Automatically running `config trust` or replacing a trust binding.
- Publishing either repository, pushing commits, or creating tags.

## Key Technical Decisions

1. **Claim with one conditional database update.** Inside a transaction, update
   `used_at` only where the persisted row is unrevoked, unused, and unexpired.
   Require exactly one affected row before issuing an API key. This works on
   SQLite and PostgreSQL and is stronger than relying only on `SELECT FOR
   UPDATE`, which SQLite does not enforce.
2. **Rollback the claim with the transaction.** Issue the API key after the
   conditional claim but in the same transaction. Any issuance/update failure
   rolls back both records.
3. **Test stale authenticated handles deterministically.** Load two instances
   before the first exchange. The second instance must fail and must not create
   another API key. This reproduces the lost-update window without a flaky
   thread/port timing test.
4. **Secrets appear only on reveal pages.** The index uses
   `<YOUR_BOOTSTRAP_TOKEN>` and never calls `secret_ciphertext` or rebuilds a
   token. A request spec scans the rendered response for the real token.
5. **Manifest is non-secret and commit-safe.** Generate only `host`, `api_base`,
   and `$HOME/.railspress/tokens/<scope>`, respecting `public_base_url`, custom
   ports/base paths, and the actual mounted engine paths.
6. **Trust remains an explicit separate step.** Instructions show `config
   check`, tell the user to review normalized values, and then show `config
   trust`. Never generate `--replace`.
7. **CLI-first with honest fallback boundaries.** Bootstrap reveal prefers
   `onboard`; direct API-key reveal prefers `token store` plus `prime`. Raw
   `curl` remains documented only as a clearly labeled manual/no-agent path.
8. **The engine owns server contracts.** RSpec covers exchange behavior and
   generated UI/docs. The agent repository owns tolerant parsing, CLI process,
   packaged artifact, and live consumer behavior.

## Granular Implementation Plan

### Phase 1: Baseline and contract inventory

- [x] Capture an engine RSpec baseline with `bin/agent-rspec baseline`.
- [x] Record the current engine commit/version expected by the agent fixture.
- [x] Confirm current public mount/base URL helpers and token-scope behavior.
- [x] Run the existing bootstrap model/request specs before changing behavior.

### Phase 2: Atomic one-time exchange

- [x] Move the active-state decision into the database transaction.
- [x] Conditionally claim only an unused, unrevoked, unexpired persisted row.
- [x] Raise `ExchangeError` unless exactly one row was claimed.
- [x] Reload the claimed record before deriving actors/owners.
- [x] Issue the API key and attach `exchanged_api_key` in the same transaction.
- [x] Preserve `used_ip`, timestamp, status, and successful response behavior.
- [x] Add a stale-handle model regression proving a second exchange cannot
      mint another API key.
- [x] Retain sequential HTTP replay coverage and assert only one API key is
      created across the successful request and replay.
- [x] Run focused model and request specs through `bin/agent-rspec run`.

### Phase 3: Safe generic Agents & API setup

- [x] Remove `latest_active_bootstrap_token` and all generic-index secret
      reconstruction.
- [x] Keep generic instructions placeholder-only when no reveal is active.
- [x] Add an always-visible “Install RailsPress Agent” card outside copied AI
      instructions.
- [x] Show supported prerequisites and review-first installer commands.
- [x] Include adapter choices and `version`/`doctor` verification commands.
- [x] Link the public agent installation documentation.
- [x] Add a copyable `RAILSPRESS.md` block generated from the current host,
      mounted API base, and site-scoped token path.
- [x] Label the manifest token-free, safe to commit, and intended for the
      publishing project root.
- [x] Add request specs for default/custom public URL and mounted path output.
- [x] Add a request spec proving the index does not contain an issued active
      bootstrap token or token-shaped bootstrap secret.

### Phase 4: CLI-first reveal instructions

- [x] Update bootstrap reveal quick start to save the manifest, review/trust
      it, and pipe the one-time token to `railspress-agent onboard --json`.
- [x] Ensure bootstrap tokens are passed on stdin and never as CLI arguments.
- [x] Update direct API-key reveal to use `railspress-agent token store` and
      `railspress-agent prime --json` after trust.
- [x] Preserve the one-time reveal warning and manual API documentation link.
- [x] Keep generic instructions token-free and distinguish “install/setup”
      from later content API operations not yet owned by the CLI.
- [x] Add request specs for CLI commands, absence of `--replace`, correct mount,
      correct token path, and absence of unsafe direct writes in preferred copy.

### Phase 5: Engine documentation

- [x] Add RailsPress Agent as the recommended setup in the main README Agents
      & API section.
- [x] Add installation and manifest guidance before the API bootstrap quick
      start in `docs/api/README.md`.
- [x] Make `docs/api/agent_bootstrap_keys.md` prefer CLI `onboard` and label raw
      `curl` as the manual/no-agent path.
- [x] Update authentication/error documentation for one-time concurrency and
      ambiguous-response recovery.
- [x] Document that `prime` is content-read-only but updates key usage metadata.
- [x] Add/update documentation contract specs for installer URL, CLI commands,
      manifest fields, and token-free examples.

### Phase 6: Verification and integration loop

- [x] Run focused engine specs after each implementation unit.
- [x] Run `bin/agent-rspec post` and `bin/agent-rspec diff`.
- [x] Run RuboCop for touched Ruby files.
- [x] Point the sibling agent live suite at this engine checkout and run its
      explicit bootstrap-to-prime integration test.
- [x] If either repository fails, fix the owning side, rerun its focused suite,
      then rerun the live seam.
- [x] Update the agent's pinned engine fixture only after the engine behavior
      and documentation are final and committed to an immutable revision; do
      not invent a commit hash for an uncommitted checkout.

## Acceptance Criteria

- A stale or concurrent second exchange cannot create a second API key.
- A failed issuance rolls back the bootstrap claim.
- The Agents & API index never includes a real bootstrap token.
- The install and manifest cards remain visible without any bootstrap key.
- Generated host/API/token values work for custom public URLs and mounts.
- Preferred bootstrap instructions invoke `railspress-agent onboard`.
- Preferred direct-key storage invokes `railspress-agent token store`.
- No generated trust command contains `--replace`.
- Engine focused and full RSpec comparisons pass.
- The sibling agent's explicit live onboarding and prime flow passes against
  this working tree.

## Open Questions Resolved During Implementation

- **Row lock or conditional update?** Use a conditional update for portable
  one-winner semantics on the engine's supported SQLite and PostgreSQL paths.
- **Should engine RSpec clone the agent?** No. Keep ordinary RSpec self-contained
  and run the consumer-owned live suite explicitly/reusably.
- **Should the generic index show the latest secret?** No. Only the dedicated
  reveal response may contain plaintext.
- **Should engine docs pin an unreleased agent version?** No. Link the stable
  installer and describe commands; the agent repository owns version pins.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/rescue_and_logging.md`
- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/domain/authentication.md`
- `docs/conventions/integrations/external_apis.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/model_specs.md`
- `docs/conventions/testing/rspec/request_specs.md`

## System and Research References

- `docs/api/agent_bootstrap_keys.md`
- `docs/api/authentication.md`
- `docs/api/prime.md`
- `docs/api/errors.md`
- `docs/research/railspress-agent-intergration.md`
- `app/models/railspress/agent_bootstrap_key.rb`
- `app/controllers/railspress/api/v1/agent_key_exchanges_controller.rb`
- `app/controllers/railspress/admin/api_keys_controller.rb`
- `app/controllers/railspress/admin/agent_bootstrap_keys_controller.rb`
- `spec/models/railspress/agent_bootstrap_key_spec.rb`
- `spec/requests/railspress/api/v1/agent_key_exchanges_spec.rb`
- `spec/requests/railspress/admin/api_keys_spec.rb`
- `spec/requests/railspress/admin/agent_bootstrap_keys_spec.rb`

## Implementation Outcome

Completed on 2026-08-22.

- Engine baseline: 907 examples, 0 failures, 1 known pending.
- Engine post suite: 910 examples, 0 failures, 1 unchanged pending.
- Baseline/post diff: no new, fixed, or unchanged failures.
- Focused RuboCop: 9 touched Ruby/spec files, no offenses.
- The sibling agent semantic contract and real live onboarding/prime flow pass
  against this working tree.
- The agent fixture SHA will be updated only after these engine changes are
  committed to an immutable revision.
