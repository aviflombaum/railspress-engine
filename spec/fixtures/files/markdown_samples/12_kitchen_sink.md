# The Kitchen Sink: A Complete Blog Post

> "The best way to test a rich text editor is to throw everything at it." — Nobody, probably

## Introduction

Welcome to **RailsPress**, a mountable blog engine for [Rails 8+](https://rubyonrails.org). This post exercises *every* Markdown feature to stress-test the Lexxy editor. If you're reading this in the editor and it looks right, we're in good shape.

---

## Getting Started

First, add the gem to your `Gemfile`:

```ruby
gem "railspress-engine", "~> 0.2.0"
```

Then run the installer:

```bash
rails generate railspress:install
rails db:migrate
```

### Configuration

Create an initializer with the features you need:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_authors
  config.author_class_name = "User"
  config.enable_post_images
  config.enable_cms

  config.inline_editing_check = ->(context) {
    context.controller.current_user&.admin?
  }
end
```

> **Note:** Inline editing requires `enable_cms`. See the [Inline Editing docs](https://example.com/docs/inline-editing) for the full setup, including the `import "railspress"` step and `yield :head` in your layout.

## Feature Comparison

| Feature | Blog Only | + CMS | + Inline Editing |
|---------|:---------:|:-----:|:----------------:|
| Posts, Categories, Tags | Yes | Yes | Yes |
| Rich text (Lexxy) | Yes | Yes | Yes |
| Content Groups | - | Yes | Yes |
| Content Elements | - | Yes | Yes |
| `cms_element` helper | - | Yes | Yes |
| Right-click editing | - | - | Yes |
| JS required on public pages | No | No | **Yes** |

## Architecture Deep Dive

The engine follows standard Rails conventions:

1. **Models** live in `app/models/railspress/`
   - `Post` — has rich text, belongs to category, has many tags
   - `Category` — simple name/slug/description
   - `ContentElement` — text or image content with versioning
2. **Controllers** use the `Admin::BaseController` inheritance chain
3. **Views** use BEM-style CSS with the `rp-` prefix

### The Content Element Lifecycle

Here's how a content element flows through the system:

1. Admin creates a `ContentGroup` (e.g., "Homepage")
2. Admin adds `ContentElement`s to the group
3. Each edit auto-creates a `ContentElementVersion`
   - Versions store the **previous** content (not current)
   - This enables `changes_from_previous` diffing
4. Public views call `cms_element("Homepage", "Hero H1")`
5. If inline editing is enabled, the output gets wrapped:

```html
<span style="display:contents"
      data-controller="rp--cms-inline-editor"
      data-rp--cms-inline-editor-element-id-value="42">
  Welcome to our site
</span>
```

### CMS Query API

The chainable API makes it easy to fetch content in controllers:

```ruby
# In a controller or service
hero = Railspress::CMS.find("Homepage").load("Hero H1").value
# => "Welcome to our site"

# Get the full element object
element = Railspress::CMS.find("Homepage").load("Hero H1").element
# => #<Railspress::ContentElement id: 42, name: "Hero H1", ...>
```

## Code Examples in Multiple Languages

### Ruby — Model with Callbacks

```ruby
class Post < ApplicationRecord
  include Railspress::Entity
  include Railspress::Taggable

  has_rich_text :content
  has_one_attached :header_image

  enum :status, { draft: 0, published: 1 }, default: :draft, scopes: false

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(status: :published).where(published_at: ..Time.current) }
  scope :search, ->(query) { where("title ILIKE ?", "%#{query}%") if query.present? }

  def scheduled?
    published_at.present? && published_at > Time.current
  end
end
```

### JavaScript — Stimulus Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class InlineEditorController extends Controller {
  static values = {
    elementId: Number,
    formFrameId: String,
    displayFrameId: String,
  }

  showMenu(event) {
    event.preventDefault()
    this.menuTarget.classList.remove("rp-cms-inline-menu--hidden")
    this.backdropTarget.classList.remove("rp-cms-inline-backdrop--hidden")
  }

  edit() {
    const frameSrc = `/railspress/admin/content_elements/${this.elementIdValue}/inline`
    this.formFrameTarget.src = `${frameSrc}?form_frame_id=${this.formFrameIdValue}`
  }
}
```

### SQL — Complex Query

```sql
SELECT
  p.title,
  p.slug,
  p.published_at,
  c.name AS category_name,
  COUNT(DISTINCT t.id) AS tag_count,
  p.reading_time
FROM railspress_posts p
LEFT JOIN railspress_categories c ON c.id = p.category_id
LEFT JOIN railspress_post_tags pt ON pt.post_id = p.id
LEFT JOIN railspress_tags t ON t.id = pt.tag_id
WHERE p.status = 1
  AND p.published_at <= CURRENT_TIMESTAMP
  AND p.published_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY p.id, c.name
HAVING COUNT(DISTINCT t.id) >= 2
ORDER BY p.published_at DESC
LIMIT 20;
```

## Common Patterns

### Task Lists for Project Tracking

- [x] Set up engine structure
- [x] Post CRUD with rich text
- [x] Categories and tags
- [x] CMS content elements
- [x] Inline editing
- [x] Feature gating (`enable_cms`)
- [ ] Full-text search
- [ ] RSS feed
- [ ] SEO meta tags

### Nested Lists with Mixed Content

- **Blog features** (always available)
  - Posts with rich text editing
  - Categories with slugs
  - Tags with CSV input
    - Auto-normalized to lowercase
    - Deduplicated on save
  - Import/export via ZIP
- **CMS features** (opt-in via `enable_cms`)
  1. Content Groups
  2. Content Elements
     - Text type
     - Image type (with Active Storage)
  3. Auto-versioning
  4. Export/import
- **Inline editing** (opt-in, requires CMS)
  > Right-click any `cms_element` on a public page to edit it in-place.

## Blockquote Styles

Simple quote:

> Ship it.

Multi-paragraph:

> The first paragraph of the quote explains the context. It's important to understand why this matters.
>
> The second paragraph provides the detail. Here we get into specifics about implementation.

Nested:

> Someone said:
>
> > "Always bet on Ruby."
>
> And they were right.

With attribution:

> The best error message is the one that never shows up.
>
> — *Thomas Fuchs*

## Images

![RailsPress admin dashboard](https://picsum.photos/800/400)

*The admin dashboard showing blog stats and recent posts.*

## Escaping and Edge Cases

Literal asterisks: \*not bold\*

Literal backticks: \`not code\`

Pipe in a table:

| Command | Description |
|---------|-------------|
| `echo "hello \| world"` | Pipe inside backticks |
| `a \| b` | Escaped pipe |

URLs with special characters: [Query string link](https://example.com/search?q=rails&page=1&sort=desc)

Long unbroken text: `Railspress::Admin::ContentElements::InlineEditingController#update_via_turbo_stream`

---

## Conclusion

If all of the above renders correctly in Lexxy — headings, bold, italic, code blocks with syntax highlighting, tables with alignment, task lists, nested quotes, images, and mixed HTML — then we're in great shape. **Ship it.** :rocket:

*Last updated: February 2026*
