# Admin Helper Reference

When customizing RailsPress admin views, these helper methods are available. They provide consistent styling and behavior across the admin interface.

## Including Helpers

Admin helpers are automatically available in RailsPress admin views. To use them in your own views or when overriding engine views, they're already included via the layout.

---

## Form Field Helpers

These helpers render form fields with consistent styling and labels.

### `rp_string_field`

Single-line text input for strings.

```erb
<%= rp_string_field form, :title %>
<%= rp_string_field form, :title, autofocus: true %>
<%= rp_string_field form, :email, placeholder: "user@example.com" %>
```

### `rp_text_field`

Multi-line textarea for longer text.

```erb
<%= rp_text_field form, :description %>
<%= rp_text_field form, :description, rows: 6 %>
```

### `rp_rich_text_field`

Rich text editor (Lexxy/ActionText) for formatted content.

```erb
<%= rp_rich_text_field form, :content %>
<%= rp_rich_text_field form, :body %>
```

### `rp_boolean_field`

Checkbox for boolean values.

```erb
<%= rp_boolean_field form, :published %>
<%= rp_boolean_field form, :featured %>
```

### `rp_datetime_field`

Datetime picker input.

```erb
<%= rp_datetime_field form, :published_at %>
<%= rp_datetime_field form, :scheduled_for %>
```

### `rp_date_field`

Date-only picker input.

```erb
<%= rp_date_field form, :birth_date %>
```

### `rp_integer_field`

Number input for integers.

```erb
<%= rp_integer_field form, :position %>
<%= rp_integer_field form, :display_order %>
```

### `rp_decimal_field`

Number input with decimal precision.

```erb
<%= rp_decimal_field form, :price %>
<%= rp_decimal_field form, :rating %>
```

### `rp_select_field`

Dropdown select input.

```erb
<%= rp_select_field form, :status, choices: %w[draft published] %>
<%= rp_select_field form, :category_id, choices: Category.all.map { |c| [c.name, c.id] } %>
<%= rp_select_field form, :role, choices: User.roles.keys, include_blank: "Select role..." %>
```

### `rp_list_field`

Text input for comma-separated lists (used with `:list` entity fields).

```erb
<%= rp_list_field form, :tech_stack %>
```

Renders with hint: "Separate items with commas"

### `rp_lines_field`

Textarea for line-separated lists (used with `:lines` entity fields).

```erb
<%= rp_lines_field form, :highlights %>
```

Renders with hint: "Enter one item per line"

### `rp_attachment_field`

File upload with preview and removal checkbox.

```erb
<%= rp_attachment_field form, :header_image, record: @post %>
<%= rp_attachment_field form, :avatar, record: @user %>
```

For multiple attachments:

```erb
<%= rp_attachment_field form, :gallery, record: @project, multiple: true %>
```

### `rp_render_field`

Generic field renderer that auto-detects the field type. Used internally by entity forms.

```erb
<%= rp_render_field form, :title, { type: :string } %>
<%= rp_render_field form, :featured, { type: :boolean } %>
```

---

## Layout Helpers

These helpers create consistent page structure and UI components.

### `rp_page_header`

Page title with optional action buttons.

```erb
<%= rp_page_header "Posts" %>

<%= rp_page_header "Posts", actions: {
  "New Post" => new_admin_post_path
} %>

<%= rp_page_header "Edit Post", actions: {
  "View" => admin_post_path(@post),
  "Delete" => admin_post_path(@post)
}, delete: admin_post_path(@post) %>
```

### `rp_card`

Card container with optional title.

```erb
<%= rp_card do %>
  <p>Card content here</p>
<% end %>

<%= rp_card title: "Statistics" do %>
  <p>Dashboard stats</p>
<% end %>
```

### `rp_form_errors`

Displays validation errors for a record.

```erb
<%= rp_form_errors(@post) %>
```

Renders nothing if no errors are present.

### `rp_sidebar_section`

Groups related form fields in the sidebar.

```erb
<%= rp_sidebar_section "Publishing" do %>
  <%= rp_select_field form, :status, choices: %w[draft published] %>
  <%= rp_datetime_field form, :published_at %>
<% end %>

<%= rp_sidebar_section "Options" do %>
  <%= rp_boolean_field form, :featured %>
  <%= rp_boolean_field form, :allow_comments %>
<% end %>
```

### `rp_empty_state`

Empty state message with optional action link.

```erb
<%= rp_empty_state "No posts yet" %>

<%= rp_empty_state "No posts yet",
    link_text: "Create your first post",
    link_path: new_admin_post_path %>
```

---

## Display Helpers

These helpers format data for display in tables and detail views.

### `rp_status_badge`

Colored badge for status values.

```erb
<%= rp_status_badge "published", type: :success %>
<%= rp_status_badge "draft", type: :warning %>
<%= rp_status_badge "archived", type: :neutral %>
<%= rp_status_badge "deleted", type: :danger %>
```

Types: `:success`, `:warning`, `:danger`, `:neutral`, `:info`

### `rp_boolean_badge`

Yes/No badge for boolean values.

```erb
<%= rp_boolean_badge(post.featured?) %>
<%# Output: "Yes" (green) or "No" (gray) %>

<%= rp_boolean_badge(post.published?, true_text: "Published", false_text: "Draft") %>
```

### `rp_attachment_badge`

Badge showing attachment status.

```erb
<%= rp_attachment_badge(post.header_image) %>
<%# Output: "Attached" or "None" %>

<%= rp_attachment_badge(project.gallery) %>
<%# Output: "3 images" or "None" %>
```

### `rp_truncated_text`

Truncates long text with ellipsis.

```erb
<%= rp_truncated_text(post.title) %>
<%# Truncates at 50 chars by default %>

<%= rp_truncated_text(post.content.to_plain_text, length: 100) %>
```

### `rp_datetime_display`

Formats datetime for display.

```erb
<%= rp_datetime_display(post.published_at) %>
<%# Output: "Jan 15, 2025 at 3:30 PM" %>

<%= rp_datetime_display(post.created_at, format: :short) %>
<%# Output: "Jan 15" %>
```

### `rp_date_display`

Formats date for display.

```erb
<%= rp_date_display(post.published_at) %>
<%# Output: "January 15, 2025" %>
```

---

## Table Helpers

Helpers for building data tables.

### `rp_table`

Wrapper for styled tables.

```erb
<%= rp_table do %>
  <thead>
    <tr>
      <th>Title</th>
      <th>Status</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <% @posts.each do |post| %>
      <tr>
        <td><%= post.title %></td>
        <td><%= rp_status_badge(post.status) %></td>
        <td><%= link_to "Edit", edit_admin_post_path(post) %></td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

### `rp_sortable_header`

Sortable column header for tables.

```erb
<th><%= rp_sortable_header "Title", :title %></th>
<th><%= rp_sortable_header "Created", :created_at %></th>
```

---

## Button Helpers

### `rp_button`

Styled button or button-style link.

```erb
<%= rp_button "Save", type: :submit %>
<%= rp_button "Cancel", path: admin_posts_path, variant: :secondary %>
<%= rp_button "Delete", path: admin_post_path(@post), variant: :danger, method: :delete, confirm: "Are you sure?" %>
```

Variants: `:primary`, `:secondary`, `:danger`, `:ghost`

### `rp_button_group`

Groups multiple buttons together.

```erb
<%= rp_button_group do %>
  <%= rp_button "Save", type: :submit %>
  <%= rp_button "Cancel", path: admin_posts_path, variant: :secondary %>
<% end %>
```

---

## Example: Custom Entity Form

Here's a complete example using these helpers:

```erb
<%# app/views/railspress/admin/entities/_form.html.erb (override) %>
<%= form_with model: @record, url: form_url, class: "rp-form" do |f| %>
  <%= rp_form_errors(@record) %>

  <div class="rp-form__layout">
    <div class="rp-form__main">
      <%= rp_string_field f, :title, autofocus: true %>
      <%= rp_text_field f, :description, rows: 4 %>
      <%= rp_rich_text_field f, :body %>
    </div>

    <div class="rp-form__sidebar">
      <%= rp_sidebar_section "Status" do %>
        <%= rp_boolean_field f, :published %>
        <%= rp_datetime_field f, :published_at %>
      <% end %>

      <%= rp_sidebar_section "Options" do %>
        <%= rp_boolean_field f, :featured %>
        <%= rp_integer_field f, :position %>
      <% end %>

      <%= rp_sidebar_section "Image" do %>
        <%= rp_attachment_field f, :cover_image, record: @record %>
      <% end %>
    </div>
  </div>

  <div class="rp-form__actions">
    <%= rp_button "Save", type: :submit %>
    <%= rp_button "Cancel", path: entity_index_path, variant: :secondary %>
  </div>
<% end %>
```

---

## CSS Classes

All RailsPress components use the `rp-` prefix. Key classes:

| Class | Element |
|-------|---------|
| `.rp-form` | Form container |
| `.rp-form__layout` | Two-column form layout |
| `.rp-form__main` | Main content column |
| `.rp-form__sidebar` | Sidebar column |
| `.rp-form-group` | Field wrapper |
| `.rp-card` | Card container |
| `.rp-btn` | Button base |
| `.rp-btn--primary` | Primary button |
| `.rp-table` | Table container |
| `.rp-badge` | Status badge |

See [Theming](THEMING.md) for CSS customization options.
