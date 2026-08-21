---
title: "Fix Blog Code Block Rendering"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
archived: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Engine baseline and dummy-host styles contain code blocks, print safely, and pass browser regressions at 375/768/1024px. Language badges were excluded because Action Text sanitizes Lexxy's editor-only language attribute."
---

# fix: Blog Code Block Rendering Issues

## Implementation Outcome

RailsPress does not own a host application's public blog view or visual theme. The implemented fix therefore keeps the engine's baseline `.trix-content pre` styles structurally safe, updates the dummy application as the reference host, and documents the CSS a host needs. Long lines scroll within the block instead of widening the document, including at 375px, 768px, and 1024px viewports; print output wraps long lines.

The proposed language badge was intentionally omitted. Lexxy may use a `language` attribute in editor content, but Action Text's default public renderer sanitizes it. RailsPress cannot expose a reliable CSS badge without changing the host's rendering/sanitization contract.

## Overview

The blog/show page renders code blocks with severe issues on mobile devices: horizontal overflow breaks page layout, extra empty lines and indentation appear in syntax-highlighted code, and there's no language badge despite the Trix editor capturing language metadata.

## Problem Statement

**Observed Issues:**
1. **Mobile horizontal overflow** - Code blocks create "insane" page widths, breaking the viewport
2. **Extra empty lines/indentation** - Syntax highlighting renders with improper spacing
3. **Unreadable language badge** - No badge exists; language info is stored but not displayed

**Root Causes Identified:**

| Issue | Root Cause | File |
|-------|-----------|------|
| Horizontal overflow | `white-space: pre` + `display: inline-block` + no mobile breakpoint | `actiontext.css:366-375` |
| Extra empty lines | `display: inline-block` on `<pre>` causes layout quirks | `actiontext.css:367` |
| No language badge | Not implemented - Trix stores `language` attr but no CSS displays it | N/A |

## Technical Context

**Current Implementation:**

```css
/* actiontext.css:366-375 - DEFAULT TRIX STYLES */
.trix-content pre {
  display: inline-block;  /* PROBLEM: causes layout issues */
  width: 100%;
  vertical-align: top;
  font-family: monospace;
  font-size: 0.9em;
  padding: 0.5em;
  white-space: pre;       /* PROBLEM: no mobile wrapping */
  background-color: #eee;
  overflow-x: auto;
}
```

**Blog show view** (`spec/dummy/app/views/blog/show.html.erb:18-20`):
```erb
<div class="post-content">
  <%= @post.content %>  <!-- Wraps in .trix-content -->
</div>
```

**Trix code block structure:**
```html
<pre language="ruby">def hello
  puts "world"
end</pre>
```

Note: Trix produces `<pre>` without a `<code>` wrapper and stores language in a `language` attribute.

## Proposed Solution

### Phase 1: Fix Code Block CSS (Immediate)

**File: `app/assets/stylesheets/actiontext.css`**

Replace the `.trix-content pre` block with responsive, mobile-first styling:

```css
/* === Code Block Fixes === */
.trix-content pre {
  position: relative;
  display: block;                    /* FIX: was inline-block */
  width: 100%;
  max-width: 100%;                   /* FIX: contain within parent */
  margin: 1.5rem 0;
  padding: 1rem;
  padding-top: 2.5rem;               /* Room for language badge */
  font-family: 'SF Mono', 'Menlo', 'Monaco', 'Consolas', monospace;
  font-size: clamp(0.75rem, 2.5vw, 0.875rem);  /* Fluid sizing */
  line-height: 1.6;
  color: #e0e0e0;
  background-color: #1e1e1e;
  border: 1px solid #333;
  border-radius: 0.5rem;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  tab-size: 2;
  white-space: pre;                  /* Desktop: preserve formatting */
}

/* Language badge */
.trix-content pre[language]::before {
  content: attr(language);
  position: absolute;
  top: 0;
  right: 0;
  padding: 0.25rem 0.75rem;
  font-family: system-ui, -apple-system, sans-serif;
  font-size: 0.625rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: rgba(255, 255, 255, 0.8);
  background-color: rgba(255, 255, 255, 0.15);
  border-radius: 0 0.5rem 0 0.25rem;
}

/* Scrollbar styling */
.trix-content pre::-webkit-scrollbar {
  height: 8px;
}

.trix-content pre::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 4px;
}

.trix-content pre::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 4px;
}

/* Mobile responsive */
@media (max-width: 767px) {
  .trix-content pre {
    margin: 1rem -1rem;              /* Bleed to screen edges */
    padding: 0.75rem 1rem;
    padding-top: 2rem;
    font-size: 0.75rem;
    border-radius: 0;
    border-left: none;
    border-right: none;
    white-space: pre-wrap;           /* FIX: wrap long lines on mobile */
    word-wrap: break-word;
    word-break: break-all;
  }

  .trix-content pre[language]::before {
    font-size: 0.5rem;
    padding: 0.2rem 0.5rem;
  }
}
```

### Phase 2: Update Blog Layout CSS (Host App)

**File: `spec/dummy/app/assets/stylesheets/application.css`** (or wherever blog styles live)

Add post-content styling that works with the improved Trix styles:

```css
.post-content {
  max-width: 100%;
  overflow-x: hidden;  /* Prevent code blocks from breaking layout */
}

@media (max-width: 767px) {
  .post-content {
    padding: 0 1rem;   /* Provide padding that code blocks can bleed past */
  }
}
```

## Acceptance Criteria

### Functional Requirements
- [ ] Code blocks render within viewport width on all screen sizes
- [ ] No horizontal page scroll caused by code blocks on mobile
- [ ] Language badge displays in top-right corner when `language` attribute is set
- [ ] Language badge is readable at all sizes (minimum 8px on mobile, 10px on desktop)
- [ ] Code preserves formatting/indentation as authored
- [ ] Empty lines between code lines render correctly (no doubling)

### Non-Functional Requirements
- [ ] Works on iOS Safari, Android Chrome, Desktop Chrome/Firefox/Safari
- [ ] No JavaScript required for basic functionality
- [ ] Vanilla CSS only (no Tailwind or framework dependencies)
- [ ] Print styles maintain readability

### Quality Gates
- [ ] Visual regression test on 375px, 768px, 1024px viewports
- [ ] Test with code blocks containing 150+ character lines
- [ ] Test with deeply nested code (8+ indent levels)
- [ ] Test with empty code blocks
- [ ] Test with no language specified

## Test Scenarios

Create a test post with these code blocks:

```markdown
1. Short Ruby code (language="ruby")
2. Long SQL query (150+ chars, language="sql")
3. Deeply nested JSON (8 levels, language="json")
4. Code with no language attribute
5. Empty pre block
6. Multiple code blocks in sequence
```

## Files to Modify

| File | Changes |
|------|---------|
| `app/assets/stylesheets/actiontext.css` | Replace `.trix-content pre` styles (lines 366-375) |
| `spec/dummy/app/assets/stylesheets/application.css` | Add `.post-content` overflow containment |

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing posts | Low | Medium | CSS-only changes, no markup changes |
| Different rendering in host apps | Medium | Low | Styles scoped to `.trix-content` |
| Print styles broken | Low | Low | Add `@media print` rules |

## Future Considerations

- **Syntax highlighting**: Consider adding Prism.js or highlight.js integration
- **Copy button**: Add clipboard functionality to code blocks
- **Line numbers**: Optional line numbering for tutorials
- **Light/dark mode**: Theme-aware syntax colors

## References

### Internal
- `app/assets/stylesheets/actiontext.css:366-375` - Current pre styling
- `app/assets/stylesheets/railspress/admin/utilities.css:76-88` - Admin prose styles (better pattern)
- `spec/dummy/app/views/blog/show.html.erb:18-20` - Blog show view

### External
- [Making Accessible, Responsive Code Blocks](https://torstenknabe.com/posts/making-accessible-responsive-code-blocks/)
- [CSS-Tricks: Make Pre Text Wrap](https://css-tricks.com/snippets/css/make-pre-text-wrap/)
- [ActionText Syntax Highlighter Gem](https://github.com/ayushn21/actiontext-syntax-highlighter)

---

**Complexity**: Low-Medium (CSS-only changes, well-defined scope)
**Files Changed**: 2
