---
title: "Add a RailsPress Doctor Command"
type: feat
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Structured diagnostics, report-only boot, migration checks, actionable output, task behavior, and specs are present."
priority: P0
---

# Add a RailsPress Doctor Command

## Goal

Add `bin/rails railspress:doctor`, a read-only command that explains the resolved RailsPress installation, identifies definite configuration/migration failures, highlights unverifiable auth and mount risks, and returns a useful process status for local use and CI.

## Context

RailsPress currently validates only selected configuration during boot. That catches missing API encryption loudly, but it does not give an operator a complete view of the engine mount, admin authentication strategy, deprecated initializer settings, or migration state. It also means a normal `:environment` Rake dependency cannot run a doctor command when the very RailsPress boot validation being diagnosed raises first.

The implementation needs a reusable diagnostic layer rather than checks embedded in Rake output. The same layer will later support `railspress:upgrade` and generator messaging.

## Scope Boundaries

### In scope

- A reusable diagnostics runner with structured findings.
- A human-readable Rake task with PASS/WARN/FAIL output and a final summary.
- A diagnostic boot mode that lets RailsPress report its own validation failures instead of raising before the task runs.
- Checks for version, engine mount, admin/current-admin configuration, API encryption, RailsPress migration copy/status, enabled features, and deprecated initializer settings.
- Focused unit and task-level specs.

### Out of scope

- Mutating files, credentials, routes, configuration, schema, or data.
- Probing URLs over HTTP or signing into the host application.
- Declaring a host secure merely because a callback, middleware, or route constraint exists.
- Discovering runtime-only deprecated method calls that have not executed.
- JSON output, plugin APIs, or a general diagnostics framework for other engines.

## Key Technical Decisions

### 1. Findings are structured before they are rendered

Introduce a small `Railspress::Diagnostics` API that returns findings with:

- stable code, such as `admin_auth_method_missing`;
- severity: `pass`, `warning`, or `failure`;
- short label;
- observed detail;
- remediation when actionable.

Keep the initial implementation simple: one diagnostics namespace/file may own the finding value object, runner, report, and text renderer. Extract individual check classes only if the implementation becomes difficult to read or test.

The report should expose `failures?` and `exit_status` so task behavior does not parse rendered strings.

### 2. Doctor gets a narrow report-only boot path

The task must not use `task doctor: :environment`, because the current RailsPress validation initializer can raise before the diagnostic code executes. Instead:

1. define the task without the `:environment` prerequisite;
2. enable an internal RailsPress report-only validation mode;
3. invoke the Rails `environment` task inside that scope;
4. run diagnostics after host initializers and routes load;
5. restore normal validation mode in `ensure`.

Normal web, console, job, and migration boots retain fail-fast validation. The bypass applies only while RailsPress's own doctor/upgrade tasks load the environment. It must not suppress unrelated Rails or host boot failures.

The report then calls the same validation predicates directly and records failures rather than relying on exceptions emitted earlier in boot.

### 3. Only definite faults fail the process

Failures should include:

- API enabled with one or more missing Active Record Encryption values.
- `admin_authentication_method` configured but not callable by `Railspress::Admin::BaseController`.
- `admin_auth_concern` configured but not resolvable/includable.
- no usable `current_admin_proc` and the configured `current_admin_method` is not callable when an enabled feature needs the admin actor.
- RailsPress migration files present in the engine but not copied into the host.
- copied RailsPress migrations pending in the current database.
- inability to inspect the current database when migration health is requested.

Warnings should include:

- no explicit `admin_authentication_method`; inherited callback/middleware/proxy protection cannot be proven.
- one or more outer constraints on the RailsPress mount, especially when API is enabled.
- zero mounts or multiple mounts, with observed paths.
- deprecated RailsPress initializer settings used during configuration.

Warnings do not make the default task exit nonzero. A PASS means the command verified a fact, not that it proved the entire host secure.

### 4. Method checks use the controller's real callable surface

Configured host methods may be private. Resolve them against `Railspress::Admin::BaseController` using public/protected/private instance-method visibility or an equivalent `respond_to?(..., true)` check on a controller instance that does not execute a request.

Do not count `_process_action_callbacks` to decide whether authentication exists. Framework callbacks already populate that chain and callback presence does not prove authorization.

### 5. Mount checks report wrappers without interpreting them

Find routes whose mounted application resolves to `Railspress::Engine`, including the mapper constraint wrapper Rails uses for a normal mount. Report:

- mount path;
- wrapper/constraint classes;
- number of mounts;
- whether API is enabled.

A non-empty constraint list produces a warning, not a boot/task failure, because its `matches?` behavior is host-defined.

### 6. Migration checks compare semantic names and database state

Reuse Rails engine migration conventions:

- Compare migration names after removing timestamps and the generated `.railspress` origin suffix; do not compare copied timestamps.
- Use the host application's migration paths/context to determine which copied RailsPress versions are pending.
- Report RailsPress migration names individually.
- Do not invoke `railspress:install:migrations`, `db:migrate`, schema dump, or any write operation.

If the database is intentionally unavailable, the task fails with a specific database-inspection finding rather than a stack trace without context. Unexpected errors should still propagate after contextual logging; do not broadly rescue and silently downgrade them.

### 7. Track deprecated configuration use at the source

Record deprecated initializer setting names when their compatibility readers/writers are called, alongside the existing `Railspress.deprecator.warn` call. Reset this registry with `reset_configuration!` so specs and reloads do not leak state.

The first version covers configuration aliases such as `current_api_actor_method` and `current_api_actor_proc`. It does not claim to detect `search`, `page`, `per_page_count`, or controller helper calls unless those code paths have actually run.

### 8. CLI output is explicit and stable enough to scan

Render to an injected IO object so output can be tested without global stdout stubs. A representative report:

```text
RailsPress doctor 1.4.5

[PASS] Mount: /railspress
[WARN] Admin authentication: no explicit method; verify signed-out access to /railspress/admin
[FAIL] Migrations: create_railspress_api_keys is not copied
[PASS] API encryption: all required values are present

1 failure, 1 warning, 2 passes
```

Rake exits successfully with warnings only and unsuccessfully when the report contains failures. Do not emit ANSI color when output is not a TTY.

## Implementation Plan

### Unit 1: Refactor validation into reportable predicates

Files:

- `lib/railspress.rb`
- `lib/railspress/active_record_encryption_configuration.rb`
- `lib/railspress/engine.rb`
- focused existing configuration/engine specs

Work:

1. Preserve the existing public `validate!` behavior for normal boot.
2. Add the narrow report-only boot scope used by RailsPress maintenance tasks.
3. Ensure both normal validation and diagnostics consume the same underlying predicates/details.
4. Prove normal application boot still raises for invalid API encryption.
5. Prove report-only task boot records the problem without raising from the RailsPress initializer.
6. Prove the scope restores normal behavior after success or exception.

### Unit 2: Add configuration deprecation tracking

Files:

- `lib/railspress.rb`
- `spec/lib/railspress/configuration_spec.rb`

Work:

1. Record each deprecated configuration alias used in the current configuration lifecycle.
2. Deduplicate repeated reads/writes.
3. Preserve the existing RailsPress deprecator warning and 2.0 horizon.
4. Clear tracked names in `reset_configuration!`.

### Unit 3: Implement the diagnostic report

Files:

- `lib/railspress/diagnostics.rb` (new)
- `lib/railspress.rb` require wiring
- `spec/lib/railspress/diagnostics_spec.rb` (new)

Work:

1. Define finding/report value objects and severity helpers.
2. Add version and enabled-feature summary.
3. Add admin auth, auth concern, and current-admin strategy checks.
4. Add API encryption check using `ActiveRecordEncryptionConfiguration`.
5. Add mount discovery and constraint warnings.
6. Add semantic migration-copy comparison and pending migration inspection.
7. Add deprecated-setting findings.
8. Render a deterministic text report to injected IO.

### Unit 4: Add the Rake task

Files:

- `lib/tasks/railspress_diagnostics_tasks.rake` (new)
- `spec/lib/tasks/railspress_diagnostics_tasks_spec.rb` or the repository-consistent task spec location (new)

Work:

1. Add the `railspress:doctor` description and task.
2. Load the Rails environment inside report-only validation scope.
3. Render the full report.
4. End unsuccessfully only when structured failures exist.
5. Ensure task exceptions retain useful context and a nonzero process result.

## Minimal Test Strategy

- Unit-test each finding through public report output/state, using the real dummy application where cheap.
- Use temporary migration directories/files for name comparison; do not alter committed dummy migrations.
- Use verifying doubles only for expensive or failure-only collaborators.
- Add task examples for all-pass/warning-only/failure exit behavior and report-only boot restoration.
- Do not test Rails's migration-copy implementation or private route wrapper internals.
- Run RSpec through the repository's `agent-rspec` workflow with `--fail-fast` semantics.

## Verification

1. Run focused configuration, encryption, engine, diagnostics, and task specs.
2. Run `bin/rubocop` on touched Ruby/spec files.
3. Run `bin/rails railspress:doctor` against the dummy app in a clean configuration.
4. Exercise one deliberately invalid dummy configuration and confirm the command reports it rather than failing before the report.
5. Confirm the same invalid configuration still stops a normal Rails runner/server boot.
6. Run `git diff --check`.

## Acceptance Criteria

- `bin/rails railspress:doctor` performs no writes.
- The command can diagnose RailsPress validation failures that would otherwise stop normal boot.
- Definite failures return nonzero; warning-only reports return zero.
- Mount and implicit-auth findings state their uncertainty and never claim security from callback presence.
- Migration checks distinguish uncopied from copied-but-pending RailsPress migrations.
- Deprecated initializer aliases are reported once without replacing the normal Rails deprecator.
- Normal RailsPress boot validation remains fail-fast.
- Repeated task runs produce the same state and equivalent report.

## Open Questions

None. Machine-readable output and opt-in warning-as-error behavior can be considered after the text contract has real consumers.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`
- `docs/conventions/operations/initializers_and_config.md`
- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/rescue_and_logging.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/isolation.md`

## Relevant System Documentation

- `plans/better-1-4-5-upgrade.md`
- `docs/UPGRADING.md`
- `docs/CONFIGURING.md`
- `docs/TROUBLESHOOTING.md`
- `lib/railspress.rb`
- `lib/railspress/engine.rb`
- `lib/railspress/active_record_encryption_configuration.rb`
- `app/controllers/railspress/admin/base_controller.rb`
- `lib/tasks/railspress_tasks.rake`
