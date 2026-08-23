---
title: "feat: format-aware post content API"
type: feat
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Format-aware Post API behavior, serialization, tests, and documentation are present."
---

# Format-Aware Post Content API

## Goal

Allow API clients to submit post content as HTML, Markdown, or plain text while storing canonical Action Text HTML and preserving the existing HTML-default contract.

## Context

`POST` and `PATCH /api/v1/posts` currently assign `post[content]` directly to Action Text. File imports accept Markdown and text, but text currently passes through the Markdown renderer. Reads already return canonical HTML.

Relevant system docs:

- [Posts API](../../docs/api/posts.md)
- [Post Imports API](../../docs/api/post_imports.md)
- [Import and export](../../docs/IMPORT_EXPORT.md)

## Scope Boundaries

In scope:

- `content_format` values `html`, `markdown`, `plain`, and `auto`
- `X-Railspress-Content-Format` as a fallback when the JSON field is omitted
- Backward-compatible HTML default
- Markdown-to-HTML conversion and literal plain-text conversion
- Correct `.txt` import behavior
- Canonical HTML plus `content_format: "html"` in JSON reads
- Request and processor coverage and API documentation

Out of scope:

- Lossless HTML-to-Markdown conversion on reads
- Persisting the source format or original Markdown
- Content negotiation that changes the entire response MIME type

## Key Technical Decisions

1. The JSON field takes precedence over the header; omitted values default to `html`.
2. `auto` must be explicitly requested because Markdown detection is inherently ambiguous.
3. Plain text is HTML-escaped and converted to paragraphs and line breaks without Markdown interpretation.
4. Action Text remains the final sanitizer and canonical storage layer.
5. Read responses always identify their content representation as `html`.

## Plan

1. Add a small `Railspress::PostContentFormatter` with format normalization, validation, detection, and conversion.
2. Apply it to API create/update content before assigning model attributes.
3. Reuse it in imports so Markdown remains rich text and `.txt` remains literal text.
4. Add request coverage for HTML, Markdown, plain text, header selection, auto detection, invalid formats, and read metadata.
5. Update processor coverage for literal text imports.
6. Update Posts, Imports, Prime, and API overview documentation.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/integrations/external_apis.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/model_specs.md`
- `docs/conventions/testing/rspec/request_specs.md`
