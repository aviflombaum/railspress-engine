---
title: Detect Redundant Host Lexxy Wiring in Doctor
type: fix
created: 2026-03-25
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
archived: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Doctor now detects redundant Lexxy pins/imports on importmap hosts, provides manual cleanup guidance, preserves intentional overrides, and never edits host files."
depends_on: .plans-archive/autoimport-lexxy.md
---

# Detect Redundant Host Lexxy Wiring in Doctor

## Decision

RailsPress detects obsolete host-owned Lexxy wiring in `railspress:doctor`. It
does not warn during every application boot and does not provide a task that
rewrites host source files.

The check is hygiene guidance, not a runtime failure. Duplicate imports are
unnecessary but harmless, and a host pin can be an intentional override of the
engine-managed Lexxy asset.

## Implemented Doctor Check

The read-only `Lexxy wiring` diagnostic inspects these host files when an
importmap is present:

- `config/importmap.rb` for a host `pin "lexxy"`
- `app/javascript/application.js` for a host `import "lexxy"`

It reports:

- `PASS` when no redundant host wiring is found.
- `WARN` when either reference is found, naming the file and explaining that
  RailsPress now pins and imports Lexxy automatically.
- A suggestion to remove the reference manually if it is obsolete, or retain
  a host pin when it intentionally overrides the engine-managed asset.

The diagnostic never edits either file and never makes Doctor fail.
Bundler-based hosts without an importmap are skipped without a warning.

## Why Doctor

Doctor is explicit, actionable, and already owns upgrade/configuration
diagnostics. A boot warning creates recurring noise, while an automatic cleanup
task cannot distinguish dead configuration from an intentional override.

## Documentation

- `docs/MAINTENANCE.md` documents the diagnostic and read-only contract.
- `docs/UPGRADING.md` documents legacy references and safe manual cleanup.
- `README.md` includes the check in the Doctor summary.
- `CHANGELOG.md` records the new diagnostic.

## Verification

- Host pin and import references each produce a warning with named files.
- Both references produce one coherent diagnostic.
- Intentional-override language appears in the suggestion.
- Missing importmaps are skipped and clean importmap hosts pass.
- Specs verify that host files remain unchanged and warnings return status 0.
- Grace Berman reports `[PASS] Lexxy wiring: managed by RailsPress`.
- Full suite: 876 examples, 0 failures, 1 existing pending example.

## Acceptance Criteria

- [x] Doctor detects redundant host Lexxy pin/import references.
- [x] Output identifies the affected files and gives safe next steps.
- [x] The result is a warning, never a failure.
- [x] No boot warning or source-mutating cleanup task is introduced.
- [x] Maintenance and upgrade documentation describe the check accurately.
