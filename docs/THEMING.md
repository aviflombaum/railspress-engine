# Theming RailsPress

RailsPress exposes CSS custom properties for the admin interface. Override them after the engine stylesheet has loaded.

## Add an Override Stylesheet

The admin layout loads `railspress/application`. A host application stylesheet is not added automatically, so either override the admin layout or append a stylesheet through your asset setup.

For example, copy the engine layout into `app/views/layouts/railspress/admin.html.erb`, preserve its existing tags, and add this after the RailsPress stylesheet:

```erb
<%= stylesheet_link_tag "railspress/application", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "railspress_overrides", "data-turbo-track": "reload" %>
```

Then define overrides in `app/assets/stylesheets/railspress_overrides.css`:

```css
:root {
  --rp-primary: #2563eb;
  --rp-sidebar-bg: #1e293b;
}
```

Dynamic values can instead be placed in a style block in the overridden layout. Sanitize or validate tenant-provided color values before emitting them into CSS.

## Design Tokens

These are all of the custom properties currently defined by RailsPress. Component-specific values that are not represented here require a selector override.

### Typography

| Variable | Default | Use |
| --- | --- | --- |
| `--rp-font-display` | `Georgia, "Times New Roman", serif` | Headings and display text |
| `--rp-font-body` | `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif` | Interface text |
| `--rp-font-mono` | `'SF Mono', Consolas, monospace` | Code and monospaced text |

### Colors

| Variable | Default | Use |
| --- | --- | --- |
| `--rp-sidebar-bg` | `#1a1d21` | Sidebar background |
| `--rp-sidebar-hover` | `#2a2e33` | Sidebar hover background |
| `--rp-sidebar-text` | `#a8adb3` | Sidebar text |
| `--rp-sidebar-text-active` | `#ffffff` | Active sidebar text |
| `--rp-bg` | `#f8f7f5` | Admin page background |
| `--rp-bg-elevated` | `#ffffff` | Cards and elevated surfaces |
| `--rp-border` | `#e5e2dc` | Standard borders |
| `--rp-border-light` | `#f0ede8` | Subtle borders |
| `--rp-text` | `#2c2a27` | Primary text |
| `--rp-text-muted` | `#6b6860` | Secondary text |
| `--rp-text-light` | `#9a958c` | Tertiary text and placeholders |
| `--rp-primary` | `#3d5a80` | Primary actions and links |
| `--rp-primary-hover` | `#2c4a6e` | Primary hover state |
| `--rp-primary-light` | `#e8eef4` | Primary tinted background |
| `--rp-success` | `#4a7c59` | Success states |
| `--rp-success-light` | `#e8f2eb` | Success tinted background |
| `--rp-danger` | `#a63d40` | Destructive and error states |
| `--rp-danger-light` | `#f9ebeb` | Error tinted background |
| `--rp-info-light` | `#f0f7fb` | Informational tinted background |

### Spacing and Sizing

| Variable | Default | Use |
| --- | --- | --- |
| `--rp-space-xs` | `0.25rem` | Extra-small spacing |
| `--rp-space-sm` | `0.5rem` | Small spacing |
| `--rp-space-md` | `1rem` | Standard spacing |
| `--rp-space-lg` | `1.5rem` | Large spacing |
| `--rp-space-xl` | `2rem` | Extra-large spacing |
| `--rp-space-2xl` | `3rem` | Largest spacing step |
| `--rp-sidebar-width` | `240px` | Expanded desktop sidebar width |
| `--rp-sidebar-width-collapsed` | `64px` | Collapsed desktop sidebar width |
| `--rp-header-height` | `56px` | Mobile header height |
| `--rp-radius` | `6px` | Shared corner radius |

### Shadows

| Variable | Default |
| --- | --- |
| `--rp-shadow-sm` | `0 1px 3px rgba(44, 42, 39, 0.06), 0 1px 2px rgba(44, 42, 39, 0.04)` |
| `--rp-shadow-md` | `0 4px 16px rgba(44, 42, 39, 0.1), 0 2px 4px rgba(44, 42, 39, 0.06)` |
| `--rp-shadow-lg` | `0 8px 24px rgba(44, 42, 39, 0.12), 0 4px 8px rgba(44, 42, 39, 0.08)` |

## Selector Overrides

RailsPress uses `rp-`-prefixed, BEM-like classes. Inspect the rendered component before overriding it; not every component detail has a custom property.

```css
/* Examples of current component selectors. */
.rp-card { }
.rp-btn--primary { }
.rp-table { }
.rp-form-group { }
```

Keep host overrides narrowly scoped to `.rp-admin-layout` where possible. Engine markup can evolve between releases, while the token list above is the preferred customization surface.

## Sidebar Behavior

The desktop sidebar uses these current selectors:

- `.rp-sidebar` is the sidebar container.
- `.rp-sidebar-toggle` is the collapse button.
- `.rp-nav-link` and `.rp-nav-link--active` style navigation links.
- `.rp-nav-icon` and `.rp-nav-text` identify the icon and label.
- `.rp-sidebar--collapsed` marks a collapsed sidebar.
- `.rp-admin-layout--sidebar-collapsed` adjusts the main content area.

The browser stores the desktop preference under the `rp-sidebar-collapsed` local-storage key. On mobile, RailsPress instead uses its hamburger control and overlay; the persisted desktop collapse state is not the mobile open state.

To change sidebar widths, override the two sizing tokens:

```css
:root {
  --rp-sidebar-width: 280px;
  --rp-sidebar-width-collapsed: 72px;
}
```

## Example Theme

```css
:root {
  --rp-primary: #047857;
  --rp-primary-hover: #065f46;
  --rp-primary-light: #d1fae5;
  --rp-sidebar-bg: #111827;
  --rp-sidebar-hover: #1f2937;
  --rp-sidebar-text: #d1d5db;
  --rp-sidebar-text-active: #ffffff;
}
```

After upgrading RailsPress, compare custom selector overrides with the current admin markup and review this token list for additions or removals.
