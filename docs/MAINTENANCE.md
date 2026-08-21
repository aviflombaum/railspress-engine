# RailsPress Maintenance Commands

RailsPress ships diagnostic, upgrade, migration-copy, and legacy data-migration tasks for host applications. Run them from the host application's root with `bin/rails`.

## Command Summary

| Command | Owner | Writes files | Writes database | Production behavior | Failure behavior |
|---------|-------|--------------|-----------------|---------------------|------------------|
| `bin/rails railspress:doctor` | RailsPress | No | No | Supported | Exits cleanly with status `1` for definite findings; warnings alone succeed |
| `DRY_RUN=1 bin/rails railspress:upgrade` | RailsPress | No | No | Supported as an inspection command | Exits nonzero when preflight fails |
| `bin/rails railspress:upgrade` | RailsPress | Yes | Yes | Refuses to mutate production | Stops on preflight, copy, migration, or postflight failure |
| `bin/rails railspress:install:migrations` | Rails engine tooling | Yes | No | Copies files when the source tree is writable | Fails if Rails cannot copy migrations |
| `bin/rails railspress:migrate_tags` | RailsPress, legacy only | No | Yes | Allowed, but review first | Transaction rolls back on count mismatch or database error |

All commands boot the host application and may connect to its configured database. “Read-only” means RailsPress does not intentionally change application files, schema, or records; normal host boot callbacks remain the host application's responsibility.

## `railspress:doctor`

```bash
bin/rails railspress:doctor
```

Doctor inspects the resolved installation and prints structured findings:

- `PASS` means RailsPress verified a fact.
- `WARN` means the result needs operator review but does not make the command fail.
- `FAIL` means the installation has a definite configuration or migration problem and the task exits nonzero.

On an interactive terminal, PASS is green, WARN is yellow, and FAIL is red. Set the standard `NO_COLOR` environment variable to disable ANSI colors. Redirected output and test/CI streams are plain text automatically.

Every warning and failure prints a `Suggestion:` line. Doctor ends with a count and a plain-language conclusion, then returns status `1` when failures require attention. Expected health findings do not raise an exception or print `rake aborted!`; this keeps output readable while preserving a useful CI exit status.

If doctor itself unexpectedly cannot boot or inspect the application, it logs the exception and prints one concise line:

```text
[ERROR] railspress:doctor threw ErrorType - message
```

It follows with a recovery suggestion and exits `1`. Add `--trace` to the command to print the backtrace in the terminal; otherwise the backtrace remains in the Rails log.

Current checks cover:

- presence and Ruby syntax of `config/initializers/railspress.rb` before the host application boots;
- exceptions raised while the RailsPress initializer is evaluated;
- enabled features and configuration validation;
- configured admin authentication method and optional authentication concern;
- current-admin method/proc when an enabled feature needs an administrator identity;
- all three Active Record Encryption values when Agents & API is enabled;
- engine mount count, path, and outer route wrappers/constraints;
- redundant host-owned Lexxy pins/imports when the host uses importmap;
- deprecated initializer settings used during boot;
- RailsPress migrations missing from the host application, including migrations for currently disabled optional features; and
- copied RailsPress migrations that remain pending in the current database.

Doctor can verify that an explicitly configured method exists. It cannot prove the authorization semantics of inherited callbacks, Rack middleware, a reverse proxy, or an arbitrary route constraint. When it warns about implicit admin protection, make a signed-out request to the reported admin URL. When it warns about an outer mount constraint and the API is enabled, verify that a bearer-token request reaches RailsPress rather than returning a routing `404` or an HTML login page.

All migrations shipped by the installed RailsPress version are part of a healthy installation. Feature flags control runtime behavior; they do not make migration files optional. When doctor reports uncopied migrations, copy all of them, review the files, apply pending migrations through the host's normal workflow, and rerun doctor.

RailsPress pins and imports Lexxy through the engine. On importmap hosts, Doctor warns when `config/importmap.rb` still pins `lexxy` or `app/javascript/application.js` still imports it. Remove obsolete references manually. Keep a host pin when it intentionally overrides the engine-managed Lexxy asset. Doctor never edits either file, and this hygiene warning does not make the command fail.

Doctor checks initializer syntax before boot so a malformed file produces a normal `FAIL` finding instead of a Ruby/Rake crash. A missing initializer is a warning because RailsPress can use its library defaults. Doctor then uses a narrow report-only RailsPress validation mode so it can report configuration dependency failures that would otherwise stop boot. Exceptions whose backtrace points to the RailsPress initializer are reported as initializer failures; unrelated host application boot failures remain unexpected errors that are logged and printed with the concise `[ERROR]` message above.

### CI use

Doctor is suitable as a post-migration verification step when CI has a configured database and the host application's production-like settings are available:

```yaml
- name: Verify RailsPress installation
  run: bin/rails railspress:doctor
```

Warnings do not fail CI. Definite failures do.

## `railspress:upgrade`

Preview an upgrade without copying or running migrations:

```bash
DRY_RUN=1 bin/rails railspress:upgrade
```

`DRY_RUN` values `1`, `true`, and `yes` are recognized case-insensitively. A dry run still boots the application, inspects routes/configuration, reads migration files, and connects to the database. It performs no RailsPress file or database writes.

Run the local/source-tree workflow:

```bash
bin/rails railspress:upgrade
```

The task:

1. runs configuration/auth/encryption/mount preflight checks;
2. lists RailsPress migrations that have not been copied;
3. lists host migrations currently known to be pending;
4. invokes `railspress:install:migrations`;
5. refreshes and prints the pending host migration list;
6. invokes `db:migrate`, which runs **all pending host migrations**, not only RailsPress migrations; and
7. runs the full doctor report as postflight verification.

Warnings do not block the workflow. A preflight or postflight failure raises `Railspress::ConfigurationError`; copy and migration failures propagate and stop later stages.

### Production deployments

The mutating upgrade task intentionally refuses to run in production. Use it in a writable development checkout, review the copied `.railspress.rb` migrations, and commit them with the host application. Then deploy and run the host's normal release step:

```bash
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails railspress:doctor
```

The production doctor remains read-only.

## `railspress:install:migrations`

```bash
bin/rails railspress:install:migrations
```

This task is provided by Rails engine tooling. It copies every missing migration from the installed RailsPress engine into the host application's `db/migrate/` directory, without consulting feature toggles. Rails assigns host timestamps and appends the `.railspress.rb` origin suffix. Existing migrations are matched by semantic migration name rather than timestamp and are skipped.

Copying does not apply a migration. Review and commit copied files, then run the host application's normal `bin/rails db:migrate` workflow.

## `railspress:migrate_tags` (Legacy Only)

This one-time data task exists for older installations that still have the `railspress_post_tags` table and need to copy those joins into the polymorphic `railspress_taggings` table.

Do not run it on a new installation. New installs create taggings directly and later drop the obsolete join table through shipped migrations.

Before running it:

1. back up the database;
2. confirm both old `railspress_post_tags` and new `railspress_taggings` tables exist;
3. inspect the old row count; and
4. run in the intended environment explicitly.

```bash
RAILS_ENV=production bin/rails railspress:migrate_tags
```

The task reads every old `post_id`/`tag_id` pair inside a transaction and uses `find_or_create_by!` for `Railspress::Post` taggings. It verifies the resulting Post tagging count against the old table count and rolls back on mismatch. It does not drop the old table; schema removal is handled separately by the shipped migration history.

Although existing pairs are not duplicated, this is a legacy data migration—not a routine retry mechanism. Inspect its output and database state before rerunning after a failure.

## Listing Available Tasks

```bash
bin/rails -T railspress
```

Use this command after upgrading to confirm which tasks the installed gem version provides.

See [Upgrading](UPGRADING.md) for the version-by-version workflow and [Troubleshooting](TROUBLESHOOTING.md) for failure-specific remediation.
