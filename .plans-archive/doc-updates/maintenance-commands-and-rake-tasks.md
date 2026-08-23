---
title: "Docs: maintenance commands and Rake task reference"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Maintenance command ownership, writes, production safety, exits, and remediation are documented."
priority: P0
---

# Maintenance Commands and Rake Task Reference

## Goal

Create one operator-facing guide for every shipped RailsPress maintenance command, with exact mutation, environment, exit-status, and version-applicability semantics.

## Audit Findings

- `railspress:doctor` and `railspress:upgrade` are mentioned across README, configuring, upgrading, and troubleshooting, but there is no complete command reference.
- `railspress:migrate_tags` exists in `lib/tasks/railspress_tasks.rake` and is only discoverable from old changelog notes/source.
- Rails's engine-provided `railspress:install:migrations` task is central to installation and upgrades but is not explained beside the RailsPress-owned tasks.
- Doctor's PASS/WARN/FAIL checks, nonzero behavior, database dependency, and CI use are scattered.
- Upgrade's production refusal, `DRY_RUN` truthy values, preflight/postflight, and its execution of *all* pending host migrations need one authoritative contract.

## Documentation Destinations

- Create `docs/MAINTENANCE.md` as a guide, not an API reference.
- Add it to `docs/README.md` and the main `README.md` documentation table.
- Keep short workflow-oriented summaries in `docs/UPGRADING.md` and `docs/TROUBLESHOOTING.md`, linking to the new guide.

## Plan

1. Add a command matrix covering owner, read/write behavior, production behavior, database requirement, and exit behavior.
2. Document `bin/rails railspress:doctor`, including every current diagnostic category: configuration, explicit/inherited admin auth, current admin identity, Active Record Encryption, mount/constraints, deprecated settings, copied migrations, and pending migrations.
3. Document `DRY_RUN=1 bin/rails railspress:upgrade` and `bin/rails railspress:upgrade` step by step; state that `1`, `true`, and `yes` are truthy and that dry run still boots the app and inspects the database/filesystem.
4. Document the normal production workflow: copy/review/commit migrations in a development checkout, deploy, run the host's normal `db:migrate`, optionally run doctor.
5. Document `railspress:install:migrations` as a Rails engine task and distinguish it from RailsPress's upgrade orchestrator.
6. Document `railspress:migrate_tags` as a legacy one-time data task for installs that still have `railspress_post_tags`; include prerequisites, count verification, idempotent `find_or_create_by!` behavior, and the fact that schema removal is a separate migration concern.
7. Add copy-paste CI examples that use doctor for verification without recommending the mutating upgrade task in production.

## Acceptance Criteria

- `bin/rails -T railspress` and the guide enumerate the same user-facing task set.
- Every task states what it reads, what it writes, and how failure is signaled.
- No guide implies doctor proves arbitrary callback/constraint authorization semantics.
- No guide implies upgrade runs RailsPress migrations selectively.
- Legacy tag migration guidance cannot be mistaken for a new-install step.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`
- `docs/conventions/operations/initializers_and_config.md`

## Relevant System Documentation

- `lib/tasks/railspress_diagnostics_tasks.rake`
- `lib/tasks/railspress_tasks.rake`
- `lib/railspress/diagnostics.rb`
- `lib/railspress/upgrade.rb`
- `docs/UPGRADING.md`
- `docs/TROUBLESHOOTING.md`
