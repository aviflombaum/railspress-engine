---
title: "Scheduled Posts"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Scheduled/live predicates and scopes, filtering, badges, public exclusion, view behavior, and specs are present."
---

# feat: Scheduled Posts

Add the ability for posts to be scheduled for future publication. A post with status "published" and `published_at` in the future should display as "Scheduled" in the UI until that date arrives.

## Overview

RailsPress already has the foundational model methods for scheduling (`scheduled?`, `live?` predicates), but the UI doesn't reflect this state and there are **scope bugs** where scheduled posts are publicly visible before their publish date.

## Problem Statement

1. **Bug**: The `published` scope doesn't filter by time, exposing scheduled posts prematurely
2. **Bug**: The `scheduled` and `live` scopes don't filter by status, returning drafts
3. **UX Gap**: Admin UI shows "Published" badge for future-dated posts instead of "Scheduled"
4. **Missing Filter**: No way to filter posts list by "Scheduled" status
5. **View Button Issue**: "View" button shows for scheduled posts but links to content that shouldn't be public yet

## Proposed Solution

Keep the existing two-state enum (draft/published) and add a `display_status` computed method. Update UI to use this method and fix all scope bugs.

**Why not add a `scheduled` enum value?**
- The model already computes scheduled state from `published_at > Time.current`
- Simpler to maintain: fewer states, no migrations needed
- Follows WordPress/Ghost pattern where "scheduled" is a display state, not a database state

## Technical Approach

### 1. Fix All Scope Bugs

```ruby
# app/models/railspress/post.rb

# Before (bugs)
scope :published, -> { where(status: :published).where.not(published_at: nil) }
scope :scheduled, -> { where("published_at > ?", Time.current) }
scope :live, -> { where("published_at <= ?", Time.current) }

# After (fixed - using Ruby ranges for clarity)
scope :published, -> { where(status: :published).where(published_at: ..Time.current) }
scope :scheduled, -> { where(status: :published).where(published_at: Time.current..) }
scope :live, -> { published }  # Alias for clarity - same as fixed published scope
scope :drafts, -> { where(status: :draft) }
```

**Note**: Ruby endless ranges naturally exclude nil values, so `.where.not(published_at: nil)` is redundant.

### 2. Add display_status Method

```ruby
# app/models/railspress/post.rb

# Returns the status to display in UI (accounts for scheduled state)
def display_status
  return "scheduled" if published? && scheduled?
  status
end
```

### 3. Update by_status Scope for Filter Handling

```ruby
# app/models/railspress/post.rb

# Handle status filter including "scheduled" virtual status
scope :by_status, ->(status) {
  case status.to_s
  when "scheduled" then scheduled
  when "published" then published
  when "draft" then drafts
  else all
  end
}
```

This keeps the controller thin - one line: `@posts = Post.by_status(params[:status])`.

### 4. Update Badge Rendering (3 files)

Replace `post.status.titleize` with `post.display_status.titleize` and use `display_status` for CSS class:

- `_post_row.html.erb:17-19`
- `show.html.erb:20`
- `dashboard/index.html.erb:37`

### 5. Add Scheduled Badge CSS

```css
/* app/assets/stylesheets/railspress/admin/badges.css */
.rp-badge--scheduled {
  background-color: var(--rp-color-info-light, #e8f4fd);
  color: var(--rp-color-info, #1e88e5);
}
```

### 6. Update Status Filter Dropdown

Add "Scheduled" option to `index.html.erb:21`:

```erb
<%= select_tag :status,
    options_for_select([
      ["All Statuses", ""],
      ["Draft", "draft"],
      ["Published", "published"],
      ["Scheduled", "scheduled"]
    ], params[:status]),
    class: "rp-select" %>
```

### 7. Fix "View" Button for Scheduled Posts

```erb
<%# show.html.erb:9-11 - only show View for live posts %>
<% if @post.live? %>
  <%= link_to "View", "#{Railspress.blog_path}/#{@post.slug}", ... %>
<% end %>
```

## Acceptance Criteria

### Functional Requirements

- [ ] Scheduled posts (status=published, published_at > now) show "Scheduled" badge in admin
- [ ] "Scheduled" filter option in posts dropdown returns only scheduled posts
- [ ] "Published" filter returns only live posts (not scheduled)
- [ ] Scheduled posts are NOT visible on public blog (filtered out by scope)
- [ ] "View" button hidden for scheduled posts
- [ ] When published_at arrives, post becomes live without manual intervention
- [ ] Editing published_at on a scheduled post updates the scheduled time
- [ ] Changing a scheduled post to "Draft" preserves published_at (allows rescheduling)

### Technical Requirements

- [ ] `display_status` method returns "scheduled" when appropriate
- [ ] `.published` scope excludes future-dated posts (uses time filter)
- [ ] `.scheduled` scope requires status=published AND future published_at
- [ ] `.live` scope aliases to `.published` for semantic clarity
- [ ] `.by_status` scope handles "scheduled" filter param
- [ ] Tests cover scheduled state transitions using `travel_to` helpers

## Files to Modify

| File | Change |
|------|--------|
| `app/models/railspress/post.rb` | Fix all scopes, add `display_status`, update `by_status` |
| `app/views/railspress/admin/posts/_post_row.html.erb` | Use `display_status` for badge |
| `app/views/railspress/admin/posts/show.html.erb` | Use `display_status`, fix View button |
| `app/views/railspress/admin/posts/index.html.erb` | Add "Scheduled" to filter dropdown |
| `app/views/railspress/admin/dashboard/index.html.erb` | Use `display_status` for badge |
| `app/assets/stylesheets/railspress/admin/badges.css` | Add `.rp-badge--scheduled` style |
| `spec/models/railspress/post_spec.rb` | Add tests for display_status and fixed scopes |
| `spec/fixtures/railspress/posts.yml` | Add scheduled_post fixture |

## Edge Cases

1. **Post scheduled for now**: If `published_at == Time.current`, treat as live (the `<=` handles this)
2. **Draft with future date**: Display as "Draft" (status takes precedence)
3. **Changing published_at to past**: Post immediately becomes live on next page load

## Out of Scope (Future)

- Background job for "post went live" notifications
- User-specific timezone preferences
- Scheduled unpublishing/archiving
- Preview route for scheduled posts
- "Schedule" vs "Publish Now" explicit buttons
- Timezone indicator in form UI

## Test Plan

```ruby
# spec/fixtures/railspress/posts.yml
scheduled_post:
  title: "Coming Soon"
  slug: "coming-soon"
  category: technology
  status: 1  # published
  published_at: <%= 1.day.from_now.to_fs(:db) %>

# spec/models/railspress/post_spec.rb

describe "#display_status" do
  it "returns 'scheduled' for published posts with future published_at" do
    post = railspress_posts(:scheduled_post)
    expect(post.display_status).to eq("scheduled")
  end

  it "returns 'published' for published posts with past published_at" do
    post = railspress_posts(:hello_world)
    expect(post.display_status).to eq("published")
  end

  it "returns 'draft' for drafts regardless of published_at" do
    post = railspress_posts(:draft_post)
    post.published_at = 1.day.from_now
    expect(post.display_status).to eq("draft")
  end
end

describe ".published scope" do
  it "excludes posts with future published_at" do
    freeze_time do
      expect(Railspress::Post.published).to include(railspress_posts(:hello_world))
      expect(Railspress::Post.published).not_to include(railspress_posts(:scheduled_post))
    end
  end
end

describe ".scheduled scope" do
  it "returns only published posts with future published_at" do
    freeze_time do
      expect(Railspress::Post.scheduled).to include(railspress_posts(:scheduled_post))
      expect(Railspress::Post.scheduled).not_to include(railspress_posts(:hello_world))
      expect(Railspress::Post.scheduled).not_to include(railspress_posts(:draft_post))
    end
  end
end

describe ".by_status scope" do
  it "handles 'scheduled' filter" do
    freeze_time do
      results = Railspress::Post.by_status("scheduled")
      expect(results).to include(railspress_posts(:scheduled_post))
      expect(results).not_to include(railspress_posts(:hello_world))
    end
  end
end
```

## References

### Internal
- Post model: `app/models/railspress/post.rb:51-76` (existing enum and scopes)
- Existing predicates: `app/models/railspress/post.rb:54-61` (`scheduled?`, `live?`)
- Badge CSS: `app/assets/stylesheets/railspress/admin/badges.css`

### External
- [WordPress Scheduled Posts](https://wordpress.com/support/schedule-a-post-or-page/)
- [Ghost Scheduling UI](https://ghost.org/help/publishing-content/)
- [Rails Time Helpers for Testing](https://andycroll.com/ruby/replace-timecop-with-rails-time-helpers-in-rspec/)
