# Admin Helper Reference

RailsPress admin views expose `Railspress::AdminHelper`. Host applications overriding engine views can use these helpers to preserve the engine's `rp-` markup and behavior. Public blog views use the two `Railspress::ApplicationHelper` methods documented at the end.

The signatures below follow `app/helpers/railspress/admin_helper.rb`. Options not consumed by a helper are forwarded to the underlying Rails form or tag helper.

## Generic Field Rendering

### `rp_render_field(form, name, type:, **options)`

Dispatches an Entity field to the matching helper. Supported types are `string`, `text`, `rich_text`, `boolean`, `datetime`, `date`, `integer`, `decimal`, `select`, `list`, `lines`, `attachment`, `attachments`, and `focal_point_image`. Unknown types fall back to a string field.

```erb
<%= rp_render_field form, :title, type: :string, primary: true %>
<%= rp_render_field form, :gallery, type: :attachments, record: @project %>
```

## Form Field Helpers

All scalar field helpers accept an optional `label:` and `hint:` unless noted.

### `rp_string_field(form, name, primary: false, mono: false, placeholder: nil, label: nil, hint: nil, **options)`

```erb
<%= rp_string_field form, :title, primary: true, autofocus: true %>
<%= rp_string_field form, :slug, mono: true, placeholder: "my-post" %>
```

### `rp_text_field(form, name, rows: 4, placeholder: nil, label: nil, hint: nil, **options)`

```erb
<%= rp_text_field form, :description, rows: 6, hint: "Shown below the title." %>
```

### `rp_rich_text_field(form, name, placeholder: nil, label: nil, hint: nil, **options)`

Renders the Lexxy/Action Text editor. The signature retains `placeholder:` for compatibility, but the current helper does not forward it to the editor.

```erb
<%= rp_rich_text_field form, :content, hint: "Write the post content." %>
```

### `rp_boolean_field(form, name, label: nil, hint: nil, **options)`

```erb
<%= rp_boolean_field form, :featured, hint: "Feature this item on the homepage." %>
```

### `rp_datetime_field(form, name, label: nil, hint: nil, **options)`

```erb
<%= rp_datetime_field form, :published_at %>
```

### `rp_date_field(form, name, label: nil, hint: nil, **options)`

```erb
<%= rp_date_field form, :event_date %>
```

### `rp_integer_field(form, name, label: nil, hint: nil, **options)`

```erb
<%= rp_integer_field form, :position, min: 0 %>
```

### `rp_decimal_field(form, name, label: nil, hint: nil, **options)`

Uses `step: "any"` unless the caller overrides it.

```erb
<%= rp_decimal_field form, :rating, min: 0, max: 5 %>
```

### `rp_select_field(form, name, choices:, include_blank: false, label: nil, hint: nil, **options)`

```erb
<%= rp_select_field form, :status,
      choices: Railspress::Post.statuses.keys.map { |value| [value.humanize, value] },
      include_blank: "Choose a status" %>
```

### `rp_list_field(form, name, placeholder: nil, label: nil, hint: nil, **options)`

Uses the Entity-generated `<name>_list` virtual attribute for comma-separated array fields. Its default hint is “Separate items with commas.”

```erb
<%= rp_list_field form, :tech_stack %>
```

### `rp_lines_field(form, name, rows: 5, placeholder: nil, label: nil, hint: nil, **options)`

Uses the Entity-generated `<name>_list` virtual attribute for one-item-per-line arrays. Its default hint is “Enter one item per line.”

```erb
<%= rp_lines_field form, :highlights %>
```

### `rp_attachment_field(form, name, multiple: false, accept: "image/*", record: nil, param_key: nil, label: nil, hint: nil, **options)`

Renders a direct-upload file input with current attachment state and removal controls. `record` defaults to `form.object`. Use `multiple: true` for `has_many_attached` fields and set `accept:` when non-image attachments are intentional.

```erb
<%= rp_attachment_field form, :header_image, record: @post %>
<%= rp_attachment_field form, :gallery, record: @project, multiple: true %>
```

### `rp_focal_point_image_field(form, name, record: nil, label: nil, **options)`

For a persisted record with an attached image, renders the compact focal-point section and editor. For a new record or missing image, renders the dropzone and explains that the record must be saved before focal-point editing is available.

```erb
<%= rp_focal_point_image_field form, :cover_image, record: @project %>
```

The model must declare focal-point support. See [Entities](ENTITIES.md#focal-point-images) and [Image Focal Points](image-focal-point-system.md).

## Form Composition

### `rp_form_errors(record)`

Returns nothing when the record has no validation errors; otherwise renders the standard error list.

```erb
<%= rp_form_errors(@post) %>
```

### `rp_form_group { ... }`

Wraps custom label/input markup in `.rp-form-group`.

```erb
<%= rp_form_group do %>
  <%= form.label :custom_code, class: rp_label_class(required: true) %>
  <%= form.text_field :custom_code, class: rp_input_class(mono: true) %>
  <%= rp_hint "Copied from the external system." %>
<% end %>
```

### `rp_form_actions(form, cancel_path, submit_text: nil)`

Renders a primary submit and secondary Cancel link in `.rp-form-actions`.

```erb
<%= rp_form_actions form, admin_posts_path, submit_text: "Save Post" %>
```

### `rp_sidebar_section(title) { ... }`

```erb
<%= rp_sidebar_section "Publishing" do %>
  <%= rp_select_field form, :status, choices: Railspress::Post.statuses.keys %>
  <%= rp_datetime_field form, :published_at %>
<% end %>
```

### `rp_hint(text)`

Renders help text with `.rp-hint`.

## Page and Container Helpers

### `rp_page_header(title, actions = {})`

Action values may be a path or `[path, html_options]`. The default class is `rp-btn rp-btn--primary`; pass a class in the options to select another button style.

```erb
<%= rp_page_header "Posts",
      "Export" => [typed_admin_exports_path(type: "posts"), class: "rp-btn rp-btn--secondary"],
      "New Post" => new_admin_post_path %>
```

### `rp_page_title(title)`

Renders a standalone page title for pages without header actions.

```erb
<%= rp_page_title "Edit Post" %>
```

### `rp_card(padded: false, **options) { ... }`

```erb
<%= rp_card(padded: true, id: "post-details") do %>
  <p>Content</p>
<% end %>
```

### `rp_empty_state(message, link_text: nil, link_path: nil)`

```erb
<%= rp_empty_state "No posts yet", link_text: "Create one", link_path: new_admin_post_path %>
```

### `rp_flash_messages`

Renders the current Rails flash collection using the RailsPress success/danger/warning/info classes. It returns nothing when the flash is empty.

```erb
<%= rp_flash_messages %>
```

## Badges and Display Values

### `rp_status_badge(value, type: nil)`

Derives the badge modifier from the lowercased value when `type:` is omitted. Supply `type:` to choose a different modifier.

```erb
<%= rp_status_badge post.display_status %>
<%= rp_status_badge "Needs review", type: :warning %>
```

### `rp_badge(text, status:)`

Low-level badge builder that emits `rp-badge--<status>` without automatic mapping.

```erb
<%= rp_badge "Internal", status: :neutral %>
```

### `rp_boolean_badge(value)`

Renders the built-in Yes/No badge. Custom true/false labels are not accepted.

### `rp_attachment_badge(attachment)`

Renders Attached/None for a single attachment or an attachment count for a multiple attachment proxy.

### `rp_truncated_text(text, length: 50)`

Returns an empty string for `nil` and otherwise uses Rails truncation.

### `rp_author_display(author)`

Returns `nil` for no author. Otherwise it tries `config.author_display_method`, then `name`, `full_name`, `display_name`, `email`, and `email_address`, finally falling back to `Author #<id>`.

```erb
<%= rp_author_display(@post.author) %>
```

## Table and Action Helpers

### `rp_sortable_header(column, label, current_sort:, current_direction:)`

Builds a link that preserves the current query parameters and toggles `direction` for the selected column.

```erb
<%= rp_sortable_header :title, "Title",
      current_sort: @sort_column,
      current_direction: @sort_direction %>
```

### `rp_table_header(label, **options)`

Renders a non-sortable header `<span>` with caller-supplied HTML attributes.

### `rp_edit_icon(path, title: "Edit")`

Renders the standard edit link with tooltip.

### `rp_delete_icon(path, confirm: "Delete this item?", title: "Delete", disabled: false, disabled_title: nil)`

Uses a Turbo confirmation when enabled. With `disabled: true`, it renders a non-interactive span; `disabled_title` explains why deletion is unavailable.

```erb
<%= rp_delete_icon admin_content_element_path(element),
      confirm: "Delete this block?",
      disabled: element.required?,
      disabled_title: "Required blocks cannot be deleted" %>
```

### `rp_table_action_icons(edit_path:, delete_path:, confirm: "Delete this item?", delete_disabled: false, disabled_title: nil)`

Combines the edit and delete helpers for a table row.

### `rp_icon(name)`

Renders an inline SVG for `:edit`, `:trash`, `:plus`, or `:search`. Unknown names return an empty string. This small icon set is the supported surface for RailsPress admin view overrides.

## Advanced CSS-Class Builders

These methods are useful when a custom field cannot use a higher-level helper.

### `rp_input_class(primary: false, mono: false, size: nil)`

Returns `.rp-input` plus optional `--title`, `--mono`, and `--<size>` modifiers.

### `rp_label_class(large: false, required: false)`

Returns `.rp-label` plus optional `--lg` and `--required` modifiers.

Prefer the field helpers when possible so labels, hints, and wrapper markup remain consistent.

## Public Blog Helpers

`Railspress::ApplicationHelper` provides:

### `rp_reading_time(post, format: :short)`

Returns `"5 min"` by default or `"5 minute read"` with `format: :long`.

### `rp_featured_image_url(post, variant: { resize_to_limit: [1200, 630] })`

Returns `nil` when no header image is attached. Otherwise returns the host URL for the requested Active Storage variant. The host needs a configured image processor when a transformation is requested.

## Custom Entity Form Example

```erb
<%= form_with model: @record, url: form_url, class: "rp-form" do |form| %>
  <%= rp_form_errors(@record) %>

  <div class="rp-form-layout">
    <div class="rp-form-main">
      <%= rp_string_field form, :title, primary: true %>
      <%= rp_rich_text_field form, :body %>
    </div>

    <div class="rp-form-sidebar">
      <%= rp_sidebar_section "Options" do %>
        <%= rp_boolean_field form, :featured %>
      <% end %>
      <%= rp_focal_point_image_field form, :cover_image, record: @record %>
    </div>
  </div>

  <%= rp_form_actions form, entity_index_path %>
<% end %>
```

See [Theming](THEMING.md) for the current CSS token and selector reference.

## Maintenance Checklist

When changing `Railspress::AdminHelper` or `Railspress::ApplicationHelper`:

1. update the relevant signature and example here;
2. remove documentation for deleted helpers;
3. verify source/helper parity with the documentation spec; and
4. update overridden-view examples in [Configuring](CONFIGURING.md) when markup expectations change.
