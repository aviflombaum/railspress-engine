# Theming RailsPress

RailsPress uses CSS custom properties (variables) for theming. Override these variables in your application's stylesheet to customize the admin interface appearance.

## Quick Start

Add to your application CSS (after loading RailsPress styles):

```css
/* app/assets/stylesheets/railspress_overrides.css */
:root {
  --rp-primary: #2563eb;
  --rp-sidebar-bg: #1e293b;
}
```

Or in your application layout:

```erb
<style>
  :root {
    --rp-primary: <%= current_tenant.brand_color %>;
  }
</style>
```

---

## Color Variables

### Brand Colors

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-primary` | `#2563eb` | Primary action color (buttons, links) |
| `--rp-primary-hover` | `#1d4ed8` | Primary hover state |
| `--rp-primary-light` | `#dbeafe` | Primary background tint |

### Semantic Colors

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-success` | `#16a34a` | Success states, published badges |
| `--rp-warning` | `#ca8a04` | Warning states, draft badges |
| `--rp-danger` | `#dc2626` | Error states, delete buttons |
| `--rp-info` | `#0891b2` | Informational elements |

### Background Colors

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-bg` | `#f8fafc` | Page background |
| `--rp-bg-card` | `#ffffff` | Card/panel background |
| `--rp-bg-muted` | `#f1f5f9` | Muted/secondary backgrounds |

### Text Colors

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-text` | `#1e293b` | Primary text |
| `--rp-text-muted` | `#64748b` | Secondary/muted text |
| `--rp-text-light` | `#94a3b8` | Light text (placeholders) |

### Border Colors

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-border` | `#e2e8f0` | Default borders |
| `--rp-border-dark` | `#cbd5e1` | Darker borders |

---

## Sidebar Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-sidebar-bg` | `#1e293b` | Sidebar background |
| `--rp-sidebar-text` | `#e2e8f0` | Sidebar text color |
| `--rp-sidebar-text-muted` | `#94a3b8` | Sidebar muted text |
| `--rp-sidebar-hover` | `#334155` | Sidebar item hover background |
| `--rp-sidebar-active` | `#0f172a` | Active sidebar item background |
| `--rp-sidebar-width` | `260px` | Sidebar width |

---

## Typography Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-font-display` | `system-ui, sans-serif` | Headings font |
| `--rp-font-body` | `system-ui, sans-serif` | Body text font |
| `--rp-font-mono` | `ui-monospace, monospace` | Code/mono font |
| `--rp-font-size-base` | `1rem` | Base font size |
| `--rp-font-size-sm` | `0.875rem` | Small text |
| `--rp-font-size-lg` | `1.125rem` | Large text |
| `--rp-line-height` | `1.5` | Default line height |

---

## Spacing Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-space-xs` | `0.25rem` | Extra small spacing |
| `--rp-space-sm` | `0.5rem` | Small spacing |
| `--rp-space-md` | `1rem` | Medium spacing (default) |
| `--rp-space-lg` | `1.5rem` | Large spacing |
| `--rp-space-xl` | `2rem` | Extra large spacing |

---

## Component Variables

### Buttons

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-btn-radius` | `0.375rem` | Button border radius |
| `--rp-btn-padding-x` | `1rem` | Horizontal padding |
| `--rp-btn-padding-y` | `0.5rem` | Vertical padding |

### Cards

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-card-radius` | `0.5rem` | Card border radius |
| `--rp-card-shadow` | `0 1px 3px rgba(0,0,0,0.1)` | Card shadow |
| `--rp-card-padding` | `1.5rem` | Card internal padding |

### Forms

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-input-radius` | `0.375rem` | Input border radius |
| `--rp-input-border` | `1px solid var(--rp-border)` | Input border |
| `--rp-input-padding` | `0.5rem 0.75rem` | Input padding |
| `--rp-input-focus-ring` | `0 0 0 3px var(--rp-primary-light)` | Focus ring |

### Badges

| Variable | Default | Description |
|----------|---------|-------------|
| `--rp-badge-radius` | `9999px` | Badge border radius (pill shape) |
| `--rp-badge-padding` | `0.25rem 0.75rem` | Badge padding |

---

## Theme Examples

### Dark Sidebar with Blue Primary

```css
:root {
  --rp-primary: #3b82f6;
  --rp-primary-hover: #2563eb;
  --rp-primary-light: #dbeafe;

  --rp-sidebar-bg: #0f172a;
  --rp-sidebar-text: #f1f5f9;
  --rp-sidebar-hover: #1e293b;
  --rp-sidebar-active: #1e40af;
}
```

### Light Theme with Green Accent

```css
:root {
  --rp-primary: #059669;
  --rp-primary-hover: #047857;
  --rp-primary-light: #d1fae5;

  --rp-sidebar-bg: #f8fafc;
  --rp-sidebar-text: #1e293b;
  --rp-sidebar-hover: #e2e8f0;
  --rp-sidebar-active: #dcfce7;

  --rp-success: #059669;
}
```

### Purple/Indigo Theme

```css
:root {
  --rp-primary: #7c3aed;
  --rp-primary-hover: #6d28d9;
  --rp-primary-light: #ede9fe;

  --rp-sidebar-bg: #1e1b4b;
  --rp-sidebar-text: #e0e7ff;
  --rp-sidebar-hover: #312e81;
  --rp-sidebar-active: #4338ca;
}
```

### Warm/Orange Theme

```css
:root {
  --rp-primary: #ea580c;
  --rp-primary-hover: #c2410c;
  --rp-primary-light: #ffedd5;

  --rp-sidebar-bg: #1c1917;
  --rp-sidebar-text: #fafaf9;
  --rp-sidebar-hover: #292524;
}
```

---

## Dynamic Theming

For multi-tenant applications, set variables dynamically:

```erb
<%# app/views/layouts/railspress/admin.html.erb (override) %>
<!DOCTYPE html>
<html>
<head>
  <%= csrf_meta_tags %>
  <%= stylesheet_link_tag "railspress/admin" %>

  <style>
    :root {
      --rp-primary: <%= current_organization.primary_color || '#2563eb' %>;
      --rp-sidebar-bg: <%= current_organization.sidebar_color || '#1e293b' %>;
    }
  </style>
</head>
<body class="rp-admin">
  <!-- ... -->
</body>
</html>
```

---

## BEM Naming Convention

RailsPress uses BEM-style CSS class naming with the `rp-` prefix:

- **Block**: `.rp-card`, `.rp-form`, `.rp-sidebar`
- **Element**: `.rp-card__header`, `.rp-form__actions`, `.rp-sidebar__nav`
- **Modifier**: `.rp-btn--primary`, `.rp-badge--success`, `.rp-card--compact`

### Key Class Patterns

```css
/* Blocks */
.rp-sidebar { }
.rp-card { }
.rp-form { }
.rp-table { }
.rp-btn { }
.rp-badge { }

/* Elements */
.rp-sidebar__header { }
.rp-sidebar__nav { }
.rp-sidebar__link { }

.rp-card__header { }
.rp-card__body { }
.rp-card__footer { }

.rp-form__layout { }
.rp-form__main { }
.rp-form__sidebar { }
.rp-form__actions { }

/* Modifiers */
.rp-btn--primary { }
.rp-btn--secondary { }
.rp-btn--danger { }
.rp-btn--ghost { }

.rp-badge--success { }
.rp-badge--warning { }
.rp-badge--danger { }
```

---

## Overriding Specific Components

To override specific components without changing variables:

```css
/* Custom card styling */
.rp-card {
  border: 2px solid var(--rp-primary);
  box-shadow: none;
}

/* Custom button styling */
.rp-btn--primary {
  background: linear-gradient(135deg, var(--rp-primary) 0%, #6366f1 100%);
}

/* Custom sidebar styling */
.rp-sidebar {
  background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
}
```

---

## Browser Support

CSS custom properties are supported in all modern browsers. For older browser support, provide fallback values:

```css
.rp-btn--primary {
  background: #2563eb; /* Fallback */
  background: var(--rp-primary);
}
```

---

## Finding All Variables

The complete list of CSS variables is defined in:

```
app/assets/stylesheets/railspress/admin/variables.css
```

View the source file for the full list of available customization points.
