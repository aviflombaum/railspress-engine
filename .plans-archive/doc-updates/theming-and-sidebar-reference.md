---
title: "Docs: theming tokens and sidebar reference"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Theming tokens, CSS behavior, sidebar extension points, and drift coverage are documented."
priority: P0
---

# Theming Tokens and Sidebar Reference

## Goal

Rebuild the theming guide from the actual CSS token and component surface so copied overrides work with the current admin UI.

## Audit Findings

- `docs/THEMING.md` documents many nonexistent tokens (`--rp-bg-card`, `--rp-warning`, component-specific radius/padding tokens, and others).
- It omits current tokens such as `--rp-bg-elevated`, light semantic colors, border-light, `--rp-space-2xl`, `--rp-radius`, header height, and shadow tokens.
- Most documented default values differ from `variables.css` after the warm-neutral redesign.
- The collapsible sidebar uses the wrong variable (`--rp-sidebar-collapsed-width` versus `--rp-sidebar-width-collapsed`) and wrong selectors (`.rp-sidebar__toggle`/`.rp-sidebar__link-text` versus `.rp-sidebar-toggle`/`.rp-nav-text`).
- Theme examples override tokens the application never reads, so they imply broader customization than exists.

## Documentation Destinations

- Rewrite `docs/THEMING.md` as a guide/reference derived from `variables.css` and actual component styles.
- Keep README's theming link but avoid duplicating token tables there.

## Plan

1. Replace token tables with the exact current variable set and defaults from `variables.css`, grouped by typography, color, spacing, sizing, and shadows.
2. Remove fictional component tokens or explicitly show selector overrides when no token exists.
3. Rework each theme example to use only tokens consumed by current CSS, then identify what still needs direct component selectors.
4. Correct the collapsible sidebar variable, state classes, DOM selectors, localStorage key, layout class, and responsive behavior.
5. Audit the BEM/class reference against templates and all admin CSS files; avoid documenting selectors that do not exist.
6. Explain asset ordering/scope so host overrides load after RailsPress and do not unintentionally theme public pages.

## Acceptance Criteria

- A token diff between `variables.css` and the guide has no unexplained entries in either direction.
- Every documented default value matches source.
- Sidebar examples use selectors/variables present in current CSS/templates.
- Every complete theme example visibly changes only supported customization points.

## Conventions

- `docs/conventions/frontend/admin_ui_patterns.md`
- `docs/conventions/frontend/css_architecture.md`
- `docs/conventions/frontend/layouts_and_views.md`

## Relevant System Documentation

- `app/assets/stylesheets/railspress/admin/variables.css`
- `app/assets/stylesheets/railspress/admin/layout.css`
- `app/assets/stylesheets/railspress/admin/responsive.css`
- `app/assets/javascripts/railspress/admin.js`
- `app/views/layouts/railspress/admin.html.erb`
- `docs/THEMING.md`
