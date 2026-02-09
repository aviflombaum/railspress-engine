# Markdown Samples

Reference files for manually testing Lexxy's rich text rendering. Copy and paste the contents into the Lexxy editor to verify how each Markdown feature renders.

These are **not** used in the automated test suite.

## Files

| File | What it tests |
|------|---------------|
| `01_headings.md` | H1-H6, headings with inline formatting |
| `02_inline_formatting.md` | Bold, italic, strikethrough, inline code, links |
| `03_paragraphs_and_line_breaks.md` | Paragraphs, hard breaks, horizontal rules |
| `04_blockquotes.md` | Simple, nested, blockquotes with embedded content |
| `05_lists.md` | Ordered, unordered, nested, task lists |
| `06_code_blocks.md` | Fenced blocks (Ruby, JS, Python, HTML, CSS, SQL, JSON, YAML, Bash, ERB) |
| `07_tables.md` | Column alignment, wide tables, inline code in cells |
| `08_images_and_media.md` | Images, linked images, reference-style |
| `09_links.md` | Inline, reference-style, autolinks |
| `10_html_mixed.md` | Inline HTML, `<details>`, `<kbd>`, definition lists |
| `11_footnotes_and_extras.md` | Footnotes, abbreviations, math, emoji |
| `12_kitchen_sink.md` | Full blog post combining all features |

## Quick Start

Start the dummy app and paste a sample into a new post:

```bash
cd spec/dummy && bin/rails server
```

Open `http://localhost:3000/railspress/admin/posts/new`, switch to Markdown mode, and paste.
