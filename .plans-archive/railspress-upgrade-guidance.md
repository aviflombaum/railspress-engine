---
title: "Unify RailsPress Upgrade Guidance"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Initializer, generator, upgrade, authentication, mount, production, and troubleshooting guidance is unified."
priority: P2
depends_on:
  - railspress-doctor
  - railspress-upgrade-task
---

# Unify RailsPress Upgrade Guidance

## Goal

Make `railspress:doctor` and `railspress:upgrade` the canonical upgrade entry points, place admin authentication settings outside the API-only initializer section, and document the 1.4.5 mount/auth symptoms in the order operators are most likely to encounter them.

## Context

The current guidance is technically accurate but distributed across the install generator, initializer comments, `UPGRADING.md`, `CONFIGURING.md`, and `TROUBLESHOOTING.md`. The initializer places browser-admin authentication settings inside the API block even though they govern every RailsPress admin installation. The 1.4.5 upgrade notes lead with encryption—which already fails loudly—while the auth/mount change can fail open or return misleading routing responses.

Once the two Rake tasks exist, documentation should explain their exact boundaries rather than preserve parallel manual checklists.

## Scope Boundaries

### In scope

- Reorganizing the generated initializer comments.
- Updating install/upgrade generator messages to point to doctor/upgrade.
- Reordering and tightening the 1.4.5 upgrade notes.
- Documenting normal local, dry-run, and production workflows.
- Documenting constrained-mount 404 and catch-all HTML-200 API symptoms.
- Documenting what doctor can verify versus what requires a signed-out request test.
- Generator specs and command/reference inventory checks.

### Out of scope

- Changing runtime authentication behavior.
- Auto-editing existing host initializers or routes.
- Adding `Railspress::MountConstraint`.
- Duplicating deprecations to stderr at every boot.
- Rewriting all historical version notes.
- Publishing a release.

## Key Technical Decisions

### 1. Authentication is a top-level initializer concern

Move these comments/settings above the optional API block:

- `config.admin_authentication_method`
- `config.current_admin_method`
- `config.current_admin_proc`
- optional `config.admin_auth_concern` guidance if the template already supports or should expose it

Explain that browser admin controllers inherit the host `ApplicationController`, while API controllers remain bearer-token authenticated on a separate stack. The API section can refer back to the current-admin identity because API-key auditing uses it, but it should not define browser security as though it were API-only.

### 2. The quick upgrade has one canonical local path

Document:

```bash
bundle update railspress-engine
DRY_RUN=1 bin/rails railspress:upgrade  # optional preview
bin/rails railspress:upgrade
```

Also document `bin/rails railspress:doctor` as the standalone command to run before/after upgrades and in troubleshooting/CI.

Keep the manual commands documented as the transparent equivalent and fallback:

```bash
bin/rails railspress:install:migrations
bin/rails db:migrate
bin/rails railspress:doctor
```

State that `db:migrate` applies every pending host migration.

### 3. Production guidance remains source-controlled

The production section must say:

- run upgrade preparation in development/source checkout;
- review and commit generated `.railspress.rb` migration files;
- deploy those files with the application;
- use the host's normal production `db:migrate` release step;
- run doctor as a read-only verification command if the environment can boot in diagnostic mode.

Do not recommend running the full `railspress:upgrade` task in production.

### 4. Lead 1.4.5 with the silent boundary change

Order the 1.4.5 notes:

1. browser admin auth and normal mount requirement;
2. API route-constraint symptoms/remediation;
3. current-admin/current-api-actor renames and doctor reporting;
4. Active Record Encryption prerequisite;
5. Stimulus/importmap/font changes.

This order emphasizes the issue that can fail open or masquerade as routing success/failure. Encryption remains prominent but no longer displaces the less visible security boundary change.

### 5. Document diagnostic uncertainty honestly

Explain that doctor can prove whether an explicitly configured method resolves, but cannot prove the authorization semantics of inherited callbacks, Rack middleware, proxies, or arbitrary route constraints. When doctor warns about implicit auth, the required operator check is a signed-out request to the reported admin URL.

### 6. Document both constrained-mount API symptoms

Add named troubleshooting cases:

- `404 No route matches` when the outer constraint rejects the request.
- `200 text/html` login/session page when a host catch-all route handles the constraint miss.

For API health, document the expected unauthenticated RailsPress response as `401` with an API response type, not `404` or a successful HTML page. The remediation remains a normal engine mount plus controller-level admin authentication.

## Implementation Plan

### Unit 1: Reorganize the initializer template

Files:

- `lib/generators/railspress/install/templates/initializer.rb`
- `spec/generators/install_generator_spec.rb`

Work:

1. Add a top-level Admin Authentication section before optional features.
2. Move the three admin/current-admin examples out of API.
3. Keep API encryption and bearer-token notes in the API section.
4. Add/adjust generator assertions for section ordering and key guidance.
5. Avoid changing existing host initializers during upgrades.

### Unit 2: Update generator completion messages

Files:

- `lib/generators/railspress/install/install_generator.rb`
- `spec/generators/install_generator_spec.rb`

Work:

1. For existing installations, point to optional dry run and the full upgrade task.
2. For new installs, continue explaining the initial migration step and recommend doctor after configuration.
3. State that RailsPress never writes encryption credentials.
4. Keep messages concise and avoid duplicating the full docs.

### Unit 3: Rewrite canonical upgrade sections

Files:

- `docs/UPGRADING.md`
- `README.md` and `docs/README.md` only where they currently summarize the upgrade command

Work:

1. Reorder the 1.4.5 section around the auth/mount boundary.
2. Replace Quick Upgrade with doctor/upgrade commands and their manual equivalent.
3. Add dry-run and production-source-control sections.
4. Clarify that full upgrade runs all pending host migrations.
5. Preserve historical manual migration internals and rollback guidance.

### Unit 4: Update configuration and troubleshooting guidance

Files:

- `docs/CONFIGURING.md`
- `docs/TROUBLESHOOTING.md`

Work:

1. Put admin authentication guidance outside API feature framing.
2. Add doctor output/remediation examples without promising callback verification.
3. Add constrained mount 404 and catch-all HTML-200 symptoms.
4. Show expected unauthenticated API `401` behavior after remediation.
5. Add doctor to migration/configuration troubleshooting entry points.

### Unit 5: Release notes and inventory

Files:

- `CHANGELOG.md`
- any command references found by a final `rg` inventory

Work:

1. Add entries for doctor, upgrade task, and migration impact.
2. State that no new engine schema migration is introduced by the tasks themselves.
3. Find stale “copy then migrate” snippets and either point to the canonical task or label them as the manual equivalent.
4. Do not rewrite historical examples where the manual commands are part of a version-specific record unless they are misleading.

## Verification

1. Run focused generator specs.
2. Run `bin/rails -T railspress` in the dummy host and confirm documented task names/descriptions.
3. Run an `rg` inventory for `railspress:install:migrations`, `railspress:doctor`, `railspress:upgrade`, `admin_authentication_method`, and constrained-mount wording.
4. Manually read the generated initializer as a new host user and as an API-disabled host user.
5. Verify every production example uses committed migrations plus the host deployment migration step.
6. Run Markdown/style checks available in the repository and `git diff --check`.

## Acceptance Criteria

- Admin authentication no longer appears to be an API-only setting.
- Local upgrades have one canonical automated command and a documented read-only preview.
- The manual copy/migrate sequence remains available and matches task behavior.
- Production docs do not recommend generating migration files inside deployed artifacts.
- Troubleshooting covers both API 404 and HTML-200 constraint-miss behavior.
- Doctor documentation distinguishes verified facts from unverifiable external auth.
- Generator output points existing installs to the upgrade task and does not claim to edit existing initializers.
- Changelog and docs state that the upgrade task runs all pending host migrations.

## Open Questions

None. Documentation URLs/anchors should use the final headings produced during implementation.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/initializers_and_config.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/isolation.md`

## Relevant System Documentation

- `plans/railspress-doctor.md`
- `plans/railspress-upgrade-task.md`
- `plans/better-1-4-5-upgrade.md`
- `docs/UPGRADING.md`
- `docs/CONFIGURING.md`
- `docs/TROUBLESHOOTING.md`
- `README.md`
- `lib/generators/railspress/install/install_generator.rb`
- `lib/generators/railspress/install/templates/initializer.rb`
