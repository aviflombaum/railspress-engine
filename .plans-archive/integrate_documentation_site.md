---
title: "Integrate Documentation Site into Engine Repo"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
implementation_location: "Separate documentation repository"
archived: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "The documentation site is complete and intentionally maintained in its separate repository rather than this engine repository."
---

# Integrate Documentation Site into Engine Repo

**Status:** Completed in the separate documentation repository. The proposed
repository merge is no longer the chosen ownership model.

Merge the separate `RailsPress.org` repository into this engine repo so everything lives in one place.

**Structure after merge:**
- `docs/` — Markdown content (API docs, guides). Already exists.
- `_site/` or `build/` — Static website output for RailsPress.org.

That's it. Details TBD.
