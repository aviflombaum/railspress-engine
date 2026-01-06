# Building a Blog with RailsPress

This guide covers how to use RailsPress to create a fully-featured blog with a recent posts feed, category pages, tag pages, and search functionality.

## Table of Contents

1. [Managing Content in the Admin](#managing-content-in-the-admin)
   - [Creating a Post](#creating-a-post)
   - [Markdown Mode](#markdown-mode)
2. [Building the Frontend Blog](#building-the-frontend-blog)
3. [Recent Posts Feed](#recent-posts-feed)
4. [Individual Post Pages](#individual-post-pages)
5. [Category Pages](#category-pages)
6. [Tag Pages](#tag-pages)
7. [Search Functionality](#search-functionality)
8. [RSS Feed](#rss-feed)
9. [SEO Optimization](#seo-optimization)

---

## Managing Content in the Admin

RailsPress provides a full admin interface at `/railspress/admin`. Here you can:

- **Create Posts**: Write blog posts with rich text content using the Lexxy editor
- **Manage Categories**: Organize posts into categories
- **Manage Tags**: Add tags for cross-cutting topics

### Creating a Post

1. Navigate to `/railspress/admin/posts/new`
2. Enter a title (slug auto-generates)
3. Write content using the rich text editor with support for:
   - Bold, italic, strikethrough
   - Headings, quotes, code blocks
   - Bullet and numbered lists
   - File uploads and images
   - Links
4. Select a category and add comma-separated tags
5. Set status to "Published" when ready
6. Click "Create Post"

### Markdown Mode

The post editor supports switching between rich text and markdown editing modes. Click the toggle button in the editor toolbar to switch modes.

**Switching to Markdown Mode:**
- Click the markdown toggle button in the editor toolbar
- Your rich text content is converted to markdown syntax
- Edit directly in markdown format
- Ideal for developers who prefer markdown

**Switching Back to Rich Text:**
- Click the toggle button again
- Markdown is converted back to HTML
- Continue editing with the visual editor

**Supported Markdown Syntax:**

| Syntax | Result |
|--------|--------|
| `# Heading` | H1 heading |
| `## Heading` | H2 heading |
| `**bold**` | Bold text |
| `*italic*` | Italic text |
| `~~strikethrough~~` | Strikethrough |
| `` `code` `` | Inline code |
| ```` ``` ```` | Code block |
| `> quote` | Blockquote |
| `- item` | Unordered list |
| `1. item` | Ordered list |
| `[text](url)` | Link |
| `![alt](url)` | Image |
| `---` | Horizontal rule |

**Important Notes:**
- Content is automatically converted when you switch modes
- On form submission, markdown is converted to HTML for storage
- Complex HTML (custom styles, nested tables) may not convert cleanly to markdown
- The rich text editor preserves all formatting when switching back

---

## Building the Frontend Blog

RailsPress provides models and data, but leaves frontend presentation to your application. This gives you full control over design and URL structure.

### Step 1: Create a Blog Controller

```ruby
# app/controllers/blog_controller.rb
class BlogController < ApplicationController
  def index
    @posts = Railspress::Post.published
                             .includes(:category, :tags)
                             .ordered
                             .page(params[:page])
                             .per(10)
  end

  def show
    @post = Railspress::Post.published.find_by!(slug: params[:slug])
    @related_posts = @post.category&.posts
                          &.published
                          &.where.not(id: @post.id)
                          &.ordered
                          &.limit(3) || []
  end

  def category
    @category = Railspress::Category.find_by!(slug: params[:slug])
    @posts = @category.posts
                      .published
                      .includes(:tags)
                      .ordered
                      .page(params[:page])
                      .per(10)
  end

  def tag
    @tag = Railspress::Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts
                 .published
                 .includes(:category)
                 .ordered
                 .page(params[:page])
                 .per(10)
  end

  def search
    @query = params[:q].to_s.strip
    @posts = if @query.present?
               Railspress::Post.published
                               .where("title ILIKE ? OR slug ILIKE ?", "%#{@query}%", "%#{@query}%")
                               .includes(:category, :tags)
                               .ordered
                               .page(params[:page])
                               .per(10)
             else
               Railspress::Post.none
             end
  end
end
```

### Step 2: Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Mount RailsPress admin
  mount Railspress::Engine => "/railspress"

  # Blog frontend routes
  get "blog", to: "blog#index", as: :blog
  get "blog/search", to: "blog#search", as: :blog_search
  get "blog/category/:slug", to: "blog#category", as: :blog_category
  get "blog/tag/:slug", to: "blog#tag", as: :blog_tag
  get "blog/:slug", to: "blog#show", as: :blog_post
end
```

### Available Scopes

RailsPress provides these scopes out of the box:

- `Railspress::Post.published` - Posts with status "published" and a `published_at` date
- `Railspress::Post.drafts` - Posts with status "draft"
- `Railspress::Post.ordered` - Posts ordered by `created_at` descending
- `Railspress::Post.recent` - Last 10 posts (combines `ordered` with `limit(10)`)

---

## Recent Posts Feed

### View: `app/views/blog/index.html.erb`

```erb
<div class="blog">
  <h1>Blog</h1>

  <%= render "blog/search_form" %>

  <div class="posts">
    <% @posts.each do |post| %>
      <article class="post-card">
        <h2>
          <%= link_to post.title, blog_post_path(slug: post.slug) %>
        </h2>

        <div class="post-meta">
          <time datetime="<%= post.published_at.iso8601 %>">
            <%= post.published_at.strftime("%B %d, %Y") %>
          </time>

          <% if post.category %>
            <span class="category">
              <%= link_to post.category.name, blog_category_path(slug: post.category.slug) %>
            </span>
          <% end %>
        </div>

        <div class="post-excerpt">
          <%= truncate(strip_tags(post.content.to_plain_text), length: 200) %>
        </div>

        <div class="post-tags">
          <% post.tags.each do |tag| %>
            <%= link_to tag.name, blog_tag_path(slug: tag.slug), class: "tag" %>
          <% end %>
        </div>

        <%= link_to "Read more", blog_post_path(slug: post.slug), class: "read-more" %>
      </article>
    <% end %>
  </div>

  <%= render "blog/pagination", collection: @posts %>
</div>
```

### Partial: `app/views/blog/_pagination.html.erb`

```erb
<% if collection.respond_to?(:total_pages) && collection.total_pages > 1 %>
  <nav class="pagination">
    <%= link_to "Previous", url_for(page: collection.prev_page), class: "prev", rel: "prev" if collection.prev_page %>

    <span class="page-info">
      Page <%= collection.current_page %> of <%= collection.total_pages %>
    </span>

    <%= link_to "Next", url_for(page: collection.next_page), class: "next", rel: "next" if collection.next_page %>
  </nav>
<% end %>
```

---

## Individual Post Pages

### View: `app/views/blog/show.html.erb`

```erb
<article class="post">
  <header class="post-header">
    <h1><%= @post.title %></h1>

    <div class="post-meta">
      <time datetime="<%= @post.published_at.iso8601 %>">
        <%= @post.published_at.strftime("%B %d, %Y") %>
      </time>

      <% if @post.category %>
        <span class="category">
          in <%= link_to @post.category.name, blog_category_path(slug: @post.category.slug) %>
        </span>
      <% end %>
    </div>
  </header>

  <div class="post-content">
    <%= @post.content %>
  </div>

  <footer class="post-footer">
    <% if @post.tags.any? %>
      <div class="post-tags">
        <strong>Tags:</strong>
        <% @post.tags.each do |tag| %>
          <%= link_to tag.name, blog_tag_path(slug: tag.slug), class: "tag" %>
        <% end %>
      </div>
    <% end %>

    <nav class="post-navigation">
      <%= link_to "Back to Blog", blog_path %>
    </nav>
  </footer>
</article>

<% if @related_posts.any? %>
  <aside class="related-posts">
    <h3>Related Posts</h3>
    <ul>
      <% @related_posts.each do |post| %>
        <li>
          <%= link_to post.title, blog_post_path(slug: post.slug) %>
          <time><%= post.published_at.strftime("%b %d") %></time>
        </li>
      <% end %>
    </ul>
  </aside>
<% end %>
```

---

## Category Pages

### View: `app/views/blog/category.html.erb`

```erb
<div class="blog blog--category">
  <header class="category-header">
    <h1>Category: <%= @category.name %></h1>
    <p><%= pluralize(@posts.total_count, "post") %></p>
  </header>

  <%= render "blog/search_form" %>

  <div class="posts">
    <% @posts.each do |post| %>
      <article class="post-card">
        <h2>
          <%= link_to post.title, blog_post_path(slug: post.slug) %>
        </h2>

        <div class="post-meta">
          <time datetime="<%= post.published_at.iso8601 %>">
            <%= post.published_at.strftime("%B %d, %Y") %>
          </time>
        </div>

        <div class="post-excerpt">
          <%= truncate(strip_tags(post.content.to_plain_text), length: 200) %>
        </div>

        <div class="post-tags">
          <% post.tags.each do |tag| %>
            <%= link_to tag.name, blog_tag_path(slug: tag.slug), class: "tag" %>
          <% end %>
        </div>
      </article>
    <% end %>
  </div>

  <%= render "blog/pagination", collection: @posts %>

  <%= link_to "View all posts", blog_path, class: "back-link" %>
</div>
```

### Categories Sidebar (optional)

```erb
<%# app/views/blog/_categories_sidebar.html.erb %>
<aside class="sidebar">
  <h3>Categories</h3>
  <ul class="category-list">
    <% Railspress::Category.ordered.each do |category| %>
      <li>
        <%= link_to blog_category_path(slug: category.slug),
            class: ("active" if @category&.id == category.id) do %>
          <%= category.name %>
          <span class="count">(<%= category.posts.published.count %>)</span>
        <% end %>
      </li>
    <% end %>
  </ul>
</aside>
```

---

## Tag Pages

### View: `app/views/blog/tag.html.erb`

```erb
<div class="blog blog--tag">
  <header class="tag-header">
    <h1>Tagged: <%= @tag.name %></h1>
    <p><%= pluralize(@posts.total_count, "post") %></p>
  </header>

  <%= render "blog/search_form" %>

  <div class="posts">
    <% @posts.each do |post| %>
      <article class="post-card">
        <h2>
          <%= link_to post.title, blog_post_path(slug: post.slug) %>
        </h2>

        <div class="post-meta">
          <time datetime="<%= post.published_at.iso8601 %>">
            <%= post.published_at.strftime("%B %d, %Y") %>
          </time>

          <% if post.category %>
            <span class="category">
              <%= link_to post.category.name, blog_category_path(slug: post.category.slug) %>
            </span>
          <% end %>
        </div>

        <div class="post-excerpt">
          <%= truncate(strip_tags(post.content.to_plain_text), length: 200) %>
        </div>
      </article>
    <% end %>
  </div>

  <%= render "blog/pagination", collection: @posts %>

  <%= link_to "View all posts", blog_path, class: "back-link" %>
</div>
```

### Tag Cloud (optional)

```erb
<%# app/views/blog/_tag_cloud.html.erb %>
<aside class="tag-cloud">
  <h3>Tags</h3>
  <div class="tags">
    <% Railspress::Tag.joins(:posts)
                      .merge(Railspress::Post.published)
                      .distinct
                      .ordered
                      .each do |tag| %>
      <%= link_to tag.name, blog_tag_path(slug: tag.slug), class: "tag" %>
    <% end %>
  </div>
</aside>
```

---

## Search Functionality

### Search Form Partial: `app/views/blog/_search_form.html.erb`

```erb
<%= form_with url: blog_search_path, method: :get, class: "search-form", data: { turbo_frame: "_top" } do |form| %>
  <%= form.search_field :q,
      value: @query,
      placeholder: "Search posts...",
      class: "search-input",
      autofocus: @query.present? %>
  <%= form.submit "Search", class: "search-button" %>
<% end %>
```

### View: `app/views/blog/search.html.erb`

```erb
<div class="blog blog--search">
  <h1>Search Results</h1>

  <%= render "blog/search_form" %>

  <% if @query.present? %>
    <p class="search-summary">
      <% if @posts.any? %>
        Found <%= pluralize(@posts.total_count, "result") %> for "<%= @query %>"
      <% else %>
        No results found for "<%= @query %>"
      <% end %>
    </p>

    <div class="posts">
      <% @posts.each do |post| %>
        <article class="post-card">
          <h2>
            <%= link_to post.title, blog_post_path(slug: post.slug) %>
          </h2>

          <div class="post-meta">
            <time datetime="<%= post.published_at.iso8601 %>">
              <%= post.published_at.strftime("%B %d, %Y") %>
            </time>

            <% if post.category %>
              <span class="category">
                <%= link_to post.category.name, blog_category_path(slug: post.category.slug) %>
              </span>
            <% end %>
          </div>

          <div class="post-excerpt">
            <%= truncate(strip_tags(post.content.to_plain_text), length: 200) %>
          </div>
        </article>
      <% end %>
    </div>

    <%= render "blog/pagination", collection: @posts %>
  <% else %>
    <p>Enter a search term above to find posts.</p>
  <% end %>

  <%= link_to "View all posts", blog_path, class: "back-link" %>
</div>
```

### Full-Text Search (PostgreSQL)

For better search with PostgreSQL, update the search action:

```ruby
# app/controllers/blog_controller.rb
def search
  @query = params[:q].to_s.strip
  @posts = if @query.present?
             Railspress::Post.published
                             .joins("LEFT JOIN action_text_rich_texts ON action_text_rich_texts.record_id = railspress_posts.id AND action_text_rich_texts.record_type = 'Railspress::Post'")
                             .where("railspress_posts.title ILIKE :q OR action_text_rich_texts.body ILIKE :q", q: "%#{@query}%")
                             .includes(:category, :tags)
                             .distinct
                             .ordered
                             .page(params[:page])
                             .per(10)
           else
             Railspress::Post.none
           end
end
```

---

## RSS Feed

### Controller Action

```ruby
# app/controllers/blog_controller.rb
def feed
  @posts = Railspress::Post.published
                           .includes(:category)
                           .ordered
                           .limit(20)

  respond_to do |format|
    format.rss { render layout: false }
  end
end
```

### Route

```ruby
get "blog/feed", to: "blog#feed", as: :blog_feed, defaults: { format: :rss }
```

### View: `app/views/blog/feed.rss.builder`

```ruby
xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Your Blog Name"
    xml.description "Your blog description"
    xml.link blog_url
    xml.language "en"
    xml.tag! "atom:link", href: blog_feed_url(format: :rss), rel: "self", type: "application/rss+xml"

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link blog_post_url(slug: post.slug)
        xml.guid blog_post_url(slug: post.slug), isPermaLink: true
        xml.pubDate post.published_at.rfc822
        xml.description strip_tags(post.content.to_plain_text).truncate(300)

        if post.category
          xml.category post.category.name
        end
      end
    end
  end
end
```

---

## SEO Optimization

### Meta Tags Helper

```ruby
# app/helpers/blog_helper.rb
module BlogHelper
  def blog_meta_title(post = nil)
    if post
      post.meta_title.presence || post.title
    else
      "Blog | Your Site Name"
    end
  end

  def blog_meta_description(post = nil)
    if post
      post.meta_description.presence || truncate(strip_tags(post.content.to_plain_text), length: 160)
    else
      "Read our latest articles and updates."
    end
  end
end
```

### Layout Head Section

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <title><%= content_for(:title) || "Your Site" %></title>
  <meta name="description" content="<%= content_for(:meta_description) || 'Default description' %>">

  <% if content_for?(:canonical_url) %>
    <link rel="canonical" href="<%= content_for(:canonical_url) %>">
  <% end %>

  <%# Open Graph %>
  <meta property="og:title" content="<%= content_for(:title) || 'Your Site' %>">
  <meta property="og:description" content="<%= content_for(:meta_description) || 'Default description' %>">
  <meta property="og:type" content="<%= content_for?(:og_type) ? content_for(:og_type) : 'website' %>">
</head>
```

### Post View with SEO

```erb
<%# app/views/blog/show.html.erb %>
<% content_for :title, blog_meta_title(@post) %>
<% content_for :meta_description, blog_meta_description(@post) %>
<% content_for :canonical_url, blog_post_url(slug: @post.slug) %>
<% content_for :og_type, "article" %>

<article class="post">
  <%# ... rest of template %>
</article>
```

---

## View Helpers

RailsPress provides helper methods for common blog display patterns. Include them in your application helper or blog helper.

### Including the Helpers

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Railspress::ApplicationHelper
end
```

Or use them directly with the module prefix:

```ruby
Railspress::ApplicationHelper.rp_reading_time(@post)
```

### `rp_reading_time`

Displays estimated reading time for a post based on word count.

```erb
<%# Short format (default) %>
<%= rp_reading_time(@post) %>
<%# Output: "5 min" %>

<%# Long format %>
<%= rp_reading_time(@post, format: :long) %>
<%# Output: "5 minute read" %>
```

Uses `Railspress.words_per_minute` (default: 200) for calculation. Configure in your initializer:

```ruby
Railspress.configure do |config|
  config.words_per_minute = 250  # faster readers
end
```

### `rp_featured_image_url`

Returns the URL for a post's header/featured image with optional variant transformation.

```erb
<%# Default (original size) %>
<img src="<%= rp_featured_image_url(@post) %>" alt="<%= @post.title %>">

<%# With variant (resized) %>
<img src="<%= rp_featured_image_url(@post, variant: { resize_to_limit: [1200, 630] }) %>"
     alt="<%= @post.title %>">

<%# For Open Graph images %>
<meta property="og:image" content="<%= rp_featured_image_url(@post, variant: { resize_to_limit: [1200, 630] }) %>">
```

Returns `nil` if:
- Header images are not enabled (`enable_post_images` not called)
- The post has no header image attached

### Example: Post Card with Reading Time

```erb
<article class="post-card">
  <% if @post.header_image.attached? %>
    <%= image_tag rp_featured_image_url(@post, variant: { resize_to_limit: [800, 400] }),
                  class: "post-card__image" %>
  <% end %>

  <h2><%= link_to @post.title, blog_post_path(slug: @post.slug) %></h2>

  <div class="post-meta">
    <time><%= @post.published_at.strftime("%B %d, %Y") %></time>
    <span class="reading-time"><%= rp_reading_time(@post) %></span>
  </div>

  <p><%= truncate(strip_tags(@post.content.to_plain_text), length: 200) %></p>
</article>
```

---

## Styling Tips

### Basic CSS Structure

```css
/* Blog layout */
.blog {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

/* Post cards */
.post-card {
  margin-bottom: 2rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid #eee;
}

.post-card h2 {
  margin: 0 0 0.5rem;
}

.post-card h2 a {
  color: inherit;
  text-decoration: none;
}

.post-card h2 a:hover {
  color: #0066cc;
}

/* Post meta */
.post-meta {
  color: #666;
  font-size: 0.875rem;
  margin-bottom: 1rem;
}

.post-meta time {
  margin-right: 1rem;
}

/* Tags */
.tag {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  background: #f0f0f0;
  border-radius: 4px;
  font-size: 0.75rem;
  text-decoration: none;
  color: #333;
  margin-right: 0.25rem;
}

.tag:hover {
  background: #e0e0e0;
}

/* Search */
.search-form {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 2rem;
}

.search-input {
  flex: 1;
  padding: 0.5rem 1rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

/* Pagination */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 2rem;
}
```

---

## Complete Example Application

For a complete working example, see the dummy app in `spec/dummy/` which demonstrates the admin interface. You can use that as a starting point and add the frontend controllers and views described in this guide.

### Quick Start Checklist

1. Add `gem 'railspress'` to your Gemfile
2. Run `bundle install`
3. Run `bin/rails railspress:install:migrations`
4. Run `bin/rails db:migrate`
5. Mount the engine: `mount Railspress::Engine => "/railspress"`
6. Create the blog controller and routes (see examples above)
7. Create the view templates
8. Add the published scope initializer
9. Start creating content at `/railspress/admin`
