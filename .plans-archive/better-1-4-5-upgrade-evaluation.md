---
title: "Evaluate and Prioritize Self-Diagnosing Upgrades"
type: plan
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "The accepted P0-P2 diagnostic, upgrade, and guidance slices are implemented; declined/deferred ideas remain intentionally absent."
---

# Evaluate and Prioritize Self-Diagnosing Upgrades

## Goal

Turn the ideas in `plans/better-1-4-5-upgrade.md` into a safe upgrade experience that gives host applications one read-only health command and one idempotent local upgrade command, without adding fragile boot-time inference or a route-level authentication bypass.

## Decision Summary

| Priority | Original idea | Decision | Destination |
|---|---|---|---|
| P0 | `railspress:doctor` | Build first. It is the reusable diagnostic foundation for every other improvement. | `plans/railspress-doctor.md` |
| P1 | `railspress:upgrade` | Build after `doctor`. It should run the local happy path: preflight, copy RailsPress migrations, run pending migrations, postflight. | `plans/railspress-upgrade-task.md` |
| P2 | Installer/template/docs follow-ups | Build with the task rollout so every upgrade path points to the same commands and auth guidance. | `plans/railspress-upgrade-guidance.md` |
| Deferred | Boot-time constrained-mount detection | Keep the detection in `doctor`; do not raise at boot. Route constraints are inspectable, but their behavior is not inferable from their presence. | Reconsider only after field experience with `doctor`. |
| Deferred | Boot-time unprotected-admin detection | Warn in `doctor`; do not infer protection from callback presence and do not fail boot. | Reconsider only if RailsPress gains an explicit strict-auth setting. |
| Declined | `Railspress::MountConstraint` compatibility wrapper | Do not ship. It would encode path/auth assumptions and make RailsPress responsible for selectively bypassing host route security. | Continue recommending a normal mount and controller-level admin auth. |
| Revised | Boot-time deprecation summary to logger and stderr | Track deprecated configuration settings and report them through `doctor`; retain the registered RailsPress deprecator for normal runtime warnings. | `plans/railspress-doctor.md` and `plans/railspress-upgrade-guidance.md` |

## Why This Ordering

### P0: establish one source of diagnostic truth

The generator, boot validation, documentation, and a future upgrade task should not each implement their own slightly different checks. `Railspress::Diagnostics` should resolve configuration once and return structured findings. The `doctor` task renders those findings and supplies a stable exit status for humans and CI.

The first release should distinguish facts from inference:

- A configured method that does not exist is a failure.
- Missing encryption settings while the API is enabled is a failure.
- An uncopied or pending RailsPress migration is a failure.
- A constrained mount is a warning because the constraint may or may not admit bearer-token requests.
- Missing explicit admin auth is a strong warning because middleware, a proxy, or an inherited callback may still protect the route.

### P1: make the documented local workflow executable

After `doctor` exists, `railspress:upgrade` can reuse the same preflight and postflight checks. The task should automate only what the currently-installed gem can safely own:

1. load the host configuration in diagnostic mode;
2. run blocking preflight checks;
3. invoke `railspress:install:migrations`;
4. show the pending migration set;
5. invoke `db:migrate`;
6. run the full diagnostic report.

It cannot update the bundle that is currently running, edit host authentication, generate or rotate encryption keys, or make production deployment choices.

### P2: collapse guidance onto the two commands

Once both tasks exist, the generator and upgrade docs should stop presenting several partially-overlapping checklists. The canonical flow becomes:

```bash
bundle update railspress-engine
bin/rails railspress:doctor
bin/rails railspress:upgrade
```

Production remains different: copied migrations are reviewed and committed with the host source, then the deployment runs its normal `db:migrate` step. `railspress:upgrade` is not a replacement for the host deployment pipeline.

## Ideas Not Accepted As Proposed

### Do not determine authentication from callback count

`Railspress::Admin::BaseController._process_action_callbacks` contains callbacks from framework integrations as well as RailsPress and the host. Even a host-supplied callback may observe or decorate a request without authenticating or halting it. Subtracting RailsPress's callback and checking whether anything remains produces both false positives and false confidence.

The diagnostic should instead report:

- whether `admin_authentication_method` is explicit and callable;
- whether `admin_auth_concern` resolves and is included;
- that inherited/external protection is not mechanically verifiable when explicit auth is absent;
- the exact admin URL the operator must test while signed out.

### Do not fail boot solely for a constrained mount

`route.app.constraints` can reveal that a mount is wrapped, but it cannot establish that the wrapper rejects `/api/v1/*`. A host constraint could allow API paths, authenticate bearer tokens itself, or apply a non-authentication condition such as tenant/domain routing. Boot-breaking behavior would therefore reject valid hosts.

`doctor` should surface the wrapper class and mount path, elevate the warning when the API is enabled, and link to the normal-mount remediation.

### Do not ship a route bypass wrapper

A generic wrapper that returns `true` for a path prefix creates a security-sensitive exception before route recognition. It must guess at mount prefixes, `SCRIPT_NAME`, API versions, and what the wrapped constraint was intended to protect. The supported architecture is simpler: mount RailsPress normally, protect browser controllers with the host method, and let API controllers authenticate bearer tokens.

### Do not duplicate every deprecation on stderr

Rails already gives the host control over the registered `Railspress.deprecator`. Writing a second boot summary to both the logger and stderr risks duplicated output and noisy test/deploy boots. The diagnostic registry should remember deprecated initializer settings used during configuration, and `doctor` should report them. Runtime-only compatibility calls such as `search` or `page` continue through the normal deprecator because they cannot be discovered at boot.

## Release Slices

1. Release slice A: diagnostics library, `railspress:doctor`, configuration-use tracking, specs.
2. Release slice B: `railspress:upgrade`, dry-run and production safeguards, task specs.
3. Release slice C: initializer template, generator output, upgrade/troubleshooting docs, changelog.
4. Observe real host results before considering any opt-in strict boot mode.

## Scope Boundaries

### In scope

- Planning the diagnostics and upgrade task contracts.
- Reusing existing Rails migration tasks rather than reimplementing migration copying or execution.
- Clear severity, output, exit-status, idempotency, and production-safety rules.
- Updating the 1.4.5 guidance and generator messaging.

### Out of scope

- Implementing any plan in this planning pass.
- Editing host routes or initializers automatically.
- Updating Bundler from inside a running Rake task.
- Generating, persisting, or rotating encryption secrets.
- Guaranteeing the semantics of arbitrary host callbacks, middleware, proxies, or route constraints.
- Publishing a release.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`
- `docs/conventions/operations/initializers_and_config.md`
- `docs/conventions/architecture/architecture.md`
- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/rescue_and_logging.md`
- `docs/conventions/data_layer/schema_conventions.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`
- `docs/conventions/testing/rspec/isolation.md`

## Relevant System Documentation

- `plans/better-1-4-5-upgrade.md`
- `docs/UPGRADING.md`
- `docs/CONFIGURING.md`
- `docs/TROUBLESHOOTING.md`
- `lib/railspress.rb`
- `lib/railspress/engine.rb`
- `lib/railspress/active_record_encryption_configuration.rb`
- `lib/generators/railspress/install/install_generator.rb`
- `lib/generators/railspress/install/templates/initializer.rb`
- `lib/tasks/railspress_tasks.rake`
