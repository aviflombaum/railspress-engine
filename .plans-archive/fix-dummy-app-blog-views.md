---
title: "Fix Dummy App Blog Views"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Dummy blog index/show rendering, nil-category related posts, Action Text output, and request specs are present."
---

# Fix Dummy App Blog Views

**Type:** Bug Fix
**Priority:** High
**Complexity:** Low

## Problem Statement

The dummy app's blog views at `http://localhost:3002/blog/how-to-use-rails-components` are crashing with:

```
NoMethodError (undefined method 'not' for nil):
app/controllers/blog_controller.rb:14:in 'BlogController#show'
```

This affects all blog posts that don't have a category assigned.

## Root Cause

In `spec/dummy/app/controllers/blog_controller.rb:12-16`:

```ruby
@related_posts = @post.category&.posts
                      &.published
                      &.where.not(id: @post.id)  # BUG: .not called on nil
                      &.ordered
                      &.limit(3) || []
```

When `@post.category` is nil, the safe navigation chain returns nil at each step until `.where.not()` which does NOT use safe navigation, causing `.not` to be called on `nil`.

## Proposed Solution

Refactor to use explicit conditional instead of chained safe navigation:

```ruby
@related_posts = if @post.category
  @post.category.posts
       .published
       .where.not(id: @post.id)
       .ordered
       .limit(3)
else
  []
end
```

## Acceptance Criteria

- [ ] Blog show page renders without error for posts WITH a category
- [ ] Blog show page renders without error for posts WITHOUT a category
- [ ] Blog index page renders all posts correctly
- [ ] Related posts section hidden when no related posts exist
- [ ] ActionText content renders properly in both views

## Implementation Tasks

### 1. Fix BlogController#show

**File:** `spec/dummy/app/controllers/blog_controller.rb`

Update the `@related_posts` query to handle nil category:

```ruby
def show
  @post = Railspress::Post.published.find_by!(slug: params[:slug])
  @related_posts = if @post.category
    @post.category.posts
         .published
         .where.not(id: @post.id)
         .ordered
         .limit(3)
  else
    []
  end
end
```

### 2. Update BlogController#index

**File:** `spec/dummy/app/controllers/blog_controller.rb`

Add preloading to avoid N+1 queries:

```ruby
def index
  @posts = Railspress::Post
    .published
    .with_rich_text_content
    .includes(:category, :tags)
    .ordered
end
```

### 3. Update Blog Views

**File:** `spec/dummy/app/views/blog/index.html.erb`

```erb
<h1>Blog</h1>

<% @posts.each do |post| %>
  <article class="post-card">
    <h2><%= link_to post.title, blog_post_path(post.slug) %></h2>

    <% if post.category %>
      <span class="post-card__category"><%= post.category.name %></span>
    <% end %>

    <p class="post-card__excerpt">
      <%= truncate(post.content.to_plain_text, length: 200) %>
    </p>

    <time datetime="<%= post.published_at&.iso8601 %>">
      <%= post.published_at&.strftime("%B %d, %Y") %>
    </time>

    <% if post.tags.any? %>
      <div class="post-card__tags">
        <% post.tags.each do |tag| %>
          <span class="tag"><%= tag.name %></span>
        <% end %>
      </div>
    <% end %>
  </article>
<% end %>
```

**File:** `spec/dummy/app/views/blog/show.html.erb`

```erb
<article class="blog-post">
  <header class="blog-post__header">
    <% if @post.category %>
      <span class="blog-post__category"><%= @post.category.name %></span>
    <% end %>

    <h1><%= @post.title %></h1>

    <time datetime="<%= @post.published_at&.iso8601 %>">
      <%= @post.published_at&.strftime("%B %d, %Y") %>
    </time>
  </header>

  <div class="blog-post__content">
    <%= @post.content %>
  </div>

  <% if @post.tags.any? %>
    <footer class="blog-post__tags">
      <strong>Tags:</strong>
      <% @post.tags.each do |tag| %>
        <span class="tag"><%= tag.name %></span>
      <% end %>
    </footer>
  <% end %>

  <% if @related_posts.any? %>
    <aside class="related-posts">
      <h3>Related Posts</h3>
      <ul>
        <% @related_posts.each do |post| %>
          <li><%= link_to post.title, blog_post_path(post.slug) %></li>
        <% end %>
      </ul>
    </aside>
  <% end %>
</article>

<p><%= link_to "Back to Blog", blog_path %></p>
```

## Edge Cases Handled

| Scenario | Expected Behavior |
|----------|-------------------|
| Post with category and tags | Full render with related posts |
| Post without category | Renders, no related posts section |
| Post without tags | Renders, no tags section |
| Post without content | Renders blank content area |
| Only post in category | Renders, related posts empty |

## Testing

After implementation, verify manually:

1. Visit `http://localhost:3002/blog` - index should load
2. Click any post - show page should load
3. Check browser console for JS errors
4. Verify posts with/without categories work

## References

- `spec/dummy/app/controllers/blog_controller.rb:14` - Bug location
- `app/models/railspress/post.rb` - Post model with scopes
- `app/models/railspress/category.rb` - Category has_many posts
- Rails ActionText docs: https://guides.rubyonrails.org/action_text_overview.html
