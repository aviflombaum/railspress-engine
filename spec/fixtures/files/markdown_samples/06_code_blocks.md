# Code Blocks

## Fenced Code Blocks (Backticks)

```
Plain code block with no language specified.
Just raw text.
```

```ruby
# Ruby
class Post < ApplicationRecord
  belongs_to :category, optional: true
  has_many :tags, through: :post_tags
  has_rich_text :content

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :published, -> { where(status: :published).where(published_at: ..Time.current) }

  def reading_time_display
    reading_time.presence || calculate_reading_time
  end
end
```

```javascript
// JavaScript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { url: String }

  async connect() {
    const response = await fetch(this.urlValue)
    const data = await response.json()
    this.outputTarget.textContent = JSON.stringify(data, null, 2)
  }
}
```

```python
# Python
def fibonacci(n: int) -> list[int]:
    """Generate Fibonacci sequence up to n terms."""
    if n <= 0:
        return []
    sequence = [0, 1]
    while len(sequence) < n:
        sequence.append(sequence[-1] + sequence[-2])
    return sequence[:n]

print(fibonacci(10))
```

```html
<!-- HTML -->
<div class="rp-card">
  <h2 class="rp-card__title">Blog Post Title</h2>
  <p class="rp-card__excerpt">
    This is the post excerpt with <strong>bold</strong> text.
  </p>
  <a href="/blog/post-slug" class="rp-card__link">Read more &rarr;</a>
</div>
```

```css
/* CSS */
.rp-card {
  border: 1px solid var(--rp-border-color);
  border-radius: 8px;
  padding: 1.5rem;
  transition: box-shadow 0.2s ease;
}

.rp-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.rp-card__title {
  font-size: 1.25rem;
  margin-bottom: 0.5rem;
}
```

```sql
-- SQL
SELECT p.title, p.slug, c.name AS category, COUNT(t.id) AS tag_count
FROM railspress_posts p
LEFT JOIN railspress_categories c ON c.id = p.category_id
LEFT JOIN railspress_post_tags pt ON pt.post_id = p.id
LEFT JOIN railspress_tags t ON t.id = pt.tag_id
WHERE p.status = 1
  AND p.published_at <= NOW()
GROUP BY p.id, p.title, p.slug, c.name
ORDER BY p.published_at DESC
LIMIT 10;
```

```json
{
  "version": 1,
  "groups": [
    {
      "name": "Homepage",
      "description": "Homepage content elements",
      "elements": [
        {
          "name": "Hero H1",
          "content_type": "text",
          "text_content": "Welcome to our site"
        }
      ]
    }
  ]
}
```

```yaml
# YAML
production:
  adapter: postgresql
  database: myapp_production
  pool: 5
  timeout: 5000
  variables:
    statement_timeout: 5000
```

```bash
# Shell
#!/bin/bash
set -euo pipefail

echo "Running migrations..."
bundle exec rails db:migrate

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Restarting server..."
pumactl restart
```

```erb
<%# ERB template %>
<% @posts.each do |post| %>
  <article class="rp-post">
    <h2><%= link_to post.title, post_path(post) %></h2>
    <time datetime="<%= post.published_at.iso8601 %>">
      <%= post.published_at.strftime("%B %d, %Y") %>
    </time>
    <div class="rp-post__excerpt">
      <%= truncate(post.excerpt, length: 200) %>
    </div>
  </article>
<% end %>
```

## Indented Code Block

    This is an indented code block.
    It uses 4 spaces of indentation.
    No language highlighting here.

## Inline Code Variations

Use `bundle exec rspec` to run tests.

Use `` `backticks` `` inside inline code (double backticks to escape).

A longer inline snippet: `Railspress::CMS.find("Homepage").load("Hero H1").value`
