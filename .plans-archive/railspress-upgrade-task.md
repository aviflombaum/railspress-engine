---
title: "Add an Idempotent RailsPress Upgrade Task"
type: feat
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Dry-run, preflight, migration copy/apply, postflight, production guard, and orchestration specs are present."
priority: P1
depends_on: railspress-doctor
---

# Add an Idempotent RailsPress Upgrade Task

## Goal

Add `bin/rails railspress:upgrade` to execute the documented local upgrade workflow after Bundler has selected the new RailsPress version: preflight diagnostics, copy RailsPress migrations, show and run pending host migrations, and verify the resulting installation.

## Context

The current upgrade guide tells every host to run `railspress:install:migrations`, inspect migration status, run `db:migrate`, and review configuration. Those steps are reasonable but easy to omit. Rails already provides the migration-copy and migration-execution tasks; RailsPress should orchestrate them rather than duplicate their behavior.

The command is intentionally not `bundle update`. A running task cannot safely replace the gem version whose code it is executing. It also cannot safely edit host routes/authentication or create encryption credentials.

## Scope Boundaries

### In scope

- `railspress:upgrade` for the full local/source-tree workflow.
- `DRY_RUN=1` to show preflight, uncopied RailsPress migrations, and currently pending host migrations without writing.
- Reuse of the structured diagnostics built for `railspress:doctor`.
- Reuse of Rails's `railspress:install:migrations` and `db:migrate` tasks.
- Fail-fast behavior, clear stage output, and safe reruns.
- A production-environment guard with deployment-specific remediation.

### Out of scope

- Running Bundler or changing the Gemfile/lockfile.
- Copying Action Text or Active Storage migrations automatically.
- Editing host initializers, routes, JavaScript, credentials, or secrets.
- Applying only selected RailsPress migrations while ignoring other pending host migrations.
- Rolling back migrations automatically.
- Replacing the host application's production deployment process.

## Key Technical Decisions

### 1. The command runs after the dependency update

Canonical local usage:

```bash
bundle update railspress-engine
bin/rails railspress:upgrade
```

The task prints the RailsPress version it is upgrading *to*. It should not invent an “upgrading from” version after Bundler has already replaced that information.

### 2. Use Rails's migration tasks as the source of truth

Invoke:

1. `railspress:install:migrations` to copy missing engine migrations using Rails's semantic-name handling and `.railspress.rb` origin suffix.
2. `db:migrate` to apply the host application's normal pending migration set.

Do not reproduce timestamp allocation, duplicate detection, migration ordering, schema dumping, or database task behavior in RailsPress code.

The command must say clearly that `db:migrate` applies **all pending host migrations**, not only RailsPress migrations. This is the same contract as the existing documented step and preserves dependency/order correctness.

### 3. Sequence checks around expected migration changes

The preflight profile should run definite non-migration checks that must be resolved before mutation, while still printing migration observations as expected work. A missing/call-invalid auth method or missing API encryption stops before files or schema change. A constrained mount or implicit auth warning is printed but does not stop the upgrade.

Sequence:

1. print target RailsPress version and environment;
2. run upgrade preflight diagnostics;
3. stop on blocking non-migration failures;
4. inventory engine migrations missing from the host and all currently pending host migrations;
5. in dry-run mode, print the intended actions and stop successfully without writes;
6. invoke `railspress:install:migrations`;
7. refresh the migration context and print the full pending migration set;
8. invoke `db:migrate`;
9. run the complete postflight doctor report;
10. fail if postflight still contains failures.

Do not rescue migration errors into a successful result. Add stage context, then allow the failure to propagate with a nonzero task exit.

### 4. Production uses committed migrations and the deployment pipeline

When `Rails.env.production?`, abort before copying or migrating and explain:

1. run `railspress:upgrade` in a writable development/source checkout;
2. review and commit generated migration files;
3. deploy that source artifact;
4. run the host's normal production `bin/rails db:migrate` step;
5. optionally run `bin/rails railspress:doctor` in the deployed environment.

Do not add a casual override flag in the first version. This avoids turning a convenience task into an undocumented production migration path. If a real deployment platform needs an override, design it from a concrete use case later.

### 5. Dry-run performs no writes

`DRY_RUN=1 bin/rails railspress:upgrade` may load the application, inspect routes/configuration, connect to the database, and enumerate files/migrations. It must not:

- invoke the migration-copy task;
- invoke `db:migrate`;
- dump schema;
- edit configuration;
- generate credentials.

This is the safe preview command recommended before a large version jump.

### 6. Reruns are supported

Rails's migration-copy task skips semantic duplicates, and `db:migrate` skips applied versions. Postflight must be read-only. A second successful run should report no RailsPress migrations to copy and no pending migrations, then finish successfully.

Because Rake memoizes task invocation within a process, task specs and any internal second invocation must explicitly re-enable delegated tasks where appropriate. Production behavior should still call each delegated task only once per upgrade execution.

## Implementation Plan

### Unit 1: Add an upgrade workflow object

Files:

- `lib/railspress/upgrade.rb` (new)
- `lib/railspress.rb` require wiring
- `spec/lib/railspress/upgrade_spec.rb` (new)

Work:

1. Accept application, diagnostics runner, Rake task adapter, environment, IO, and dry-run flag at the command boundary.
2. Keep one public `call` method that performs the ordered stages.
3. Reuse diagnostic findings rather than parsing doctor text.
4. Inventory missing RailsPress and pending host migrations for display.
5. Stop before mutation on production or blocking preflight failures.
6. Invoke Rails migration tasks in order for a normal run.
7. Refresh state and run full postflight diagnostics.
8. Let delegated task failures propagate after printing the failed stage.

Dependency injection is limited to the command boundary so the orchestration can be tested without modifying a real database; normal application code uses default real collaborators.

### Unit 2: Add the Rake entry point

Files:

- `lib/tasks/railspress_upgrade_tasks.rake` (new, or colocated with the diagnostics task if that is clearer during implementation)
- task spec file in the same convention chosen for `railspress:doctor`

Work:

1. Add `railspress:upgrade` with a precise task description.
2. Load the host environment through the same report-only RailsPress validation scope as doctor.
3. Parse `DRY_RUN` with explicit truthy values rather than Ruby string truthiness.
4. Call the workflow and preserve its nonzero failure behavior.
5. Ensure the task appears correctly under `bin/rails -T railspress` in a host app.

### Unit 3: Cover orchestration and idempotency

Test cases:

- Blocking preflight failure invokes neither copy nor migrate.
- Warning-only preflight continues.
- Dry-run invokes neither mutating task and prints planned changes.
- Normal run invokes copy before migrate and then postflight.
- A delegated copy/migrate failure stops later stages and remains nonzero.
- Production aborts before any mutation with deployment guidance.
- A clean second run reports no work and succeeds.
- Output states that all pending host migrations will run.

Use verifying doubles for the Rake task boundary and real diagnostic value objects. Add one dummy-app integration smoke test for actual task registration/output; do not repeatedly migrate the committed test database in unit examples.

## Verification

1. Run focused diagnostics, upgrade workflow, and Rake task specs.
2. Run `DRY_RUN=1 bin/rails railspress:upgrade` against the dummy app and confirm `git status` and migration status are unchanged.
3. In a temporary host app or disposable copy of the dummy app, remove one copied RailsPress migration, run the full task, and confirm it copies then applies it.
4. Run the task a second time and confirm a clean no-op result.
5. Confirm a production-environment invocation aborts before file/database mutation.
6. Run RuboCop on touched Ruby/spec files and `git diff --check`.

## Acceptance Criteria

- The task automates copy + migrate + verification after the user updates the gem.
- `DRY_RUN=1` is demonstrably read-only.
- The task never runs Bundler or creates/rotates credentials.
- Production aborts before mutation and points to the normal committed-migration deployment flow.
- All pending host migrations are listed before `db:migrate` and the output states they will all run.
- Migration errors fail fast and remain visible.
- Postflight uses the same findings and severity rules as `railspress:doctor`.
- Running a completed upgrade again is safe and succeeds without duplicate migrations.

## Open Questions

None. Interactive confirmation and selective migration execution are intentionally omitted; `DRY_RUN=1` supplies reviewability without making CI behavior depend on a TTY.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`
- `docs/conventions/architecture/architecture.md`
- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/rescue_and_logging.md`
- `docs/conventions/data_layer/schema_conventions.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/isolation.md`

## Relevant System Documentation

- `plans/railspress-doctor.md`
- `plans/better-1-4-5-upgrade.md`
- `docs/UPGRADING.md`
- `lib/tasks/railspress_tasks.rake`
- `lib/generators/railspress/install/install_generator.rb`
- Rails engine-provided `railspress:install:migrations` task
- Rails `db:migrate` task and host migration context
