module Railspress
  # Helper methods for building consistent admin views.
  # Use these helpers to ensure styling consistency across all entity views.
  module AdminHelper

    # ============================================================
    # FIELD RENDERING HELPERS
    # ============================================================

    # Master dispatcher that renders the appropriate input based on type.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param type [Symbol] the field type (:string, :text, :rich_text, :boolean, :datetime, :date, :integer, :decimal, :attachment, :attachments, :select)
    # @param options [Hash] additional options passed to the specific renderer
    # @return [String] rendered HTML
    #
    # @example Basic usage
    #   rp_render_field(f, :title, type: :string)
    #   rp_render_field(f, :content, type: :rich_text)
    #   rp_render_field(f, :featured, type: :boolean, label: "Featured post?")
    def rp_render_field(form, name, type:, **options)
      case type
      when :string
        rp_string_field(form, name, **options)
      when :text
        rp_text_field(form, name, **options)
      when :rich_text
        rp_rich_text_field(form, name, **options)
      when :boolean
        rp_boolean_field(form, name, **options)
      when :datetime
        rp_datetime_field(form, name, **options)
      when :date
        rp_date_field(form, name, **options)
      when :integer
        rp_integer_field(form, name, **options)
      when :decimal
        rp_decimal_field(form, name, **options)
      when :attachment
        rp_attachment_field(form, name, multiple: false, **options)
      when :attachments
        rp_attachment_field(form, name, multiple: true, **options)
      when :focal_point_image
        rp_focal_point_image_field(form, name, **options)
      when :select
        rp_select_field(form, name, **options)
      when :list
        rp_list_field(form, name, **options)
      when :lines
        rp_lines_field(form, name, **options)
      else
        rp_string_field(form, name, **options)
      end
    end

    # Renders a string input field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param primary [Boolean] whether this is the primary/title input
    # @param mono [Boolean] whether to use monospace font
    # @param placeholder [String] placeholder text
    # @param required [Boolean] whether field is required
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_string_field(form, name, primary: false, mono: false, placeholder: nil, required: false, label: nil, hint: nil, **options)
      placeholder ||= "Enter #{name.to_s.humanize.downcase}..."
      input_class = rp_input_class(primary: primary, mono: mono)

      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: rp_label_class(required: required))
        output += form.text_field(name, class: input_class, placeholder: placeholder, required: required, **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a text area field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param rows [Integer] number of rows
    # @param placeholder [String] placeholder text
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_text_field(form, name, rows: 4, placeholder: nil, label: nil, hint: nil, **options)
      placeholder ||= "Enter #{name.to_s.humanize.downcase}..."

      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.text_area(name, rows: rows, class: "rp-input", placeholder: placeholder, **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a rich text (Trix) editor field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param placeholder [String] placeholder text
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_rich_text_field(form, name, placeholder: nil, label: nil, hint: nil, **options)
      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.rich_text_area(name, class: "rp-rich-text", **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a boolean checkbox field.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param label [String] custom label text
    # @return [String] rendered HTML
    def rp_boolean_field(form, name, label: nil, hint: nil, **options)
      label_text = label || name.to_s.humanize

      content_tag(:div, class: "rp-form-group") do
        content_tag(:label, class: "rp-checkbox-label") do
          form.check_box(name, options) + " ".html_safe + label_text
        end +
        (hint ? content_tag(:span, hint, class: "rp-hint") : "".html_safe)
      end
    end

    # Renders a datetime-local input field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_datetime_field(form, name, label: nil, hint: nil, **options)
      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.datetime_local_field(name, class: "rp-input", **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a date input field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_date_field(form, name, label: nil, hint: nil, **options)
      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.date_field(name, class: "rp-input", **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders an integer number input field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_integer_field(form, name, label: nil, hint: nil, **options)
      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.number_field(name, class: "rp-input", step: 1, **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a decimal number input field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_decimal_field(form, name, label: nil, hint: nil, **options)
      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.number_field(name, class: "rp-input", step: "any", **options)
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a select dropdown field with label.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param choices [Array] options for select (array of [text, value] or just values)
    # @param include_blank [Boolean, String] whether to include blank option
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    #
    # @example Basic usage
    #   rp_select_field(f, :status, choices: Post.statuses.keys)
    #   rp_select_field(f, :category_id, choices: Category.pluck(:name, :id), include_blank: "No category")
    def rp_select_field(form, name, choices:, include_blank: false, label: nil, hint: nil, **options)
      content_tag(:div, class: "rp-form-group") do
        output = form.label(name, label, class: "rp-label")
        output += form.select(name, choices, { include_blank: include_blank }, { class: "rp-select" }.merge(options))
        output += rp_hint(hint) if hint
        output
      end
    end

    # Renders a comma-separated list input field with label.
    # Uses the virtual attribute `#{name}_list` for form binding.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name (e.g., :tech_stack)
    # @param placeholder [String] placeholder text
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    #
    # @example Usage
    #   rp_list_field(f, :tech_stack)
    #   rp_list_field(f, :tech_stack, hint: "Add technologies separated by commas")
    def rp_list_field(form, name, placeholder: nil, label: nil, hint: nil, **options)
      virtual_name = "#{name}_list"
      placeholder ||= "Item 1, Item 2, Item 3"

      content_tag(:div, class: "rp-form-group") do
        output = form.label(virtual_name, label || name.to_s.humanize, class: "rp-label")
        output += form.text_field(virtual_name, class: "rp-input", placeholder: placeholder, **options)
        output += rp_hint(hint || "Separate items with commas")
        output
      end
    end

    # Renders a line-separated list textarea field with label.
    # Uses the virtual attribute `#{name}_list` for form binding.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name (e.g., :highlights)
    # @param rows [Integer] number of textarea rows
    # @param placeholder [String] placeholder text
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    #
    # @example Usage
    #   rp_lines_field(f, :highlights)
    #   rp_lines_field(f, :highlights, rows: 6, hint: "Each line becomes one item")
    def rp_lines_field(form, name, rows: 5, placeholder: nil, label: nil, hint: nil, **options)
      virtual_name = "#{name}_list"
      placeholder ||= "One item per line"

      content_tag(:div, class: "rp-form-group") do
        output = form.label(virtual_name, label || name.to_s.humanize, class: "rp-label")
        output += form.text_area(virtual_name, rows: rows, class: "rp-input", placeholder: placeholder, **options)
        output += rp_hint(hint || "Enter one item per line")
        output
      end
    end

    # Renders a file attachment field with preview and removal option.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the field name
    # @param multiple [Boolean] whether to allow multiple files
    # @param accept [String] accepted file types (e.g., "image/*")
    # @param record [ActiveRecord::Base] the record (defaults to form.object)
    # @param param_key [String] the param key for removal checkbox
    # @param label [String] custom label text
    # @param hint [String] hint text shown below input
    # @return [String] rendered HTML
    def rp_attachment_field(form, name, multiple: false, accept: "image/*", record: nil, param_key: nil, label: nil, hint: nil, **options)
      record ||= form.object
      param_key ||= record.model_name.param_key
      attachment = record.public_send(name)

      content_tag(:div, class: "rp-form-group") do
        output = "".html_safe

        if multiple && attachment.attached?
          # Multiple attachments preview
          output += content_tag(:div, class: "rp-gallery-preview") do
            attachment.map do |att|
              content_tag(:div, class: "rp-gallery-item") do
                item = if att.image?
                  image_tag(main_app.url_for(att), class: "rp-gallery-thumb")
                else
                  content_tag(:div, class: "rp-gallery-file") do
                    content_tag(:span, "📄", class: "rp-gallery-file-icon") +
                    content_tag(:span, att.filename, class: "rp-gallery-file-name")
                  end
                end
                item += content_tag(:label, class: "rp-gallery-remove") do
                  check_box_tag("#{param_key}[remove_#{name}][]", att.id, false) + " Remove"
                end
                item
              end
            end.join.html_safe
          end
          output += form.label(name, label || "Add images", class: "rp-label")
          output += form.file_field(name, multiple: true, accept: accept, class: "rp-file-input", direct_upload: true, **options)
          output += rp_hint(hint || "Select multiple images to upload") if hint != false
        elsif !multiple && attachment.attached?
          # Single attachment preview
          output += content_tag(:div, class: "rp-attachment-preview") do
            preview = if attachment.image?
              image_tag(main_app.url_for(attachment), class: "rp-attachment-thumb")
            else
              content_tag(:div, class: "rp-attachment-file") do
                content_tag(:span, attachment.filename, class: "rp-attachment-file-name")
              end
            end
            preview += content_tag(:label, class: "rp-attachment-remove") do
              check_box_tag("#{param_key}[remove_#{name}]", "1", false) + " Remove"
            end
            preview
          end
          output += form.label(name, label, class: "rp-label")
          output += form.file_field(name, accept: accept, class: "rp-file-input", direct_upload: true, **options)
          output += rp_hint(hint) if hint
        else
          # No attachment yet
          output += form.label(name, label, class: "rp-label")
          if multiple
            output += form.file_field(name, multiple: true, accept: accept, class: "rp-file-input", direct_upload: true, **options)
          else
            output += form.file_field(name, accept: accept, class: "rp-file-input", direct_upload: true, **options)
          end
          output += rp_hint(hint) if hint
        end

        output
      end
    end

    # Renders a focal point image field with the compact/editor UI.
    # For persisted records with images, shows the compact view with Edit button.
    # For new records or no image, shows a dropzone upload.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param name [Symbol] the attachment field name (e.g., :main_image)
    # @param record [ActiveRecord::Base] the record (defaults to form.object)
    # @param label [String] custom label text
    # @return [String] rendered HTML
    def rp_focal_point_image_field(form, name, record: nil, label: nil, **options)
      record ||= form.object
      label ||= name.to_s.humanize
      attachment = record.public_send(name)
      has_image = attachment.attached? && attachment.blob&.persisted?

      if record.persisted? && has_image
        # Persisted record with image - render focal point compact view
        render partial: "railspress/admin/shared/image_section_compact",
               locals: {
                 record: record,
                 attachment_name: name,
                 label: label
               }
      else
        # New record or no image - render dropzone
        content_tag(:div, class: "rp-form-group") do
          output = content_tag(:label, label, class: "rp-label")
          if has_image
            # Image uploaded but record not saved yet - show preview
            output += content_tag(:div, class: "rp-image-section__compact") do
              preview = content_tag(:div, class: "rp-image-section__thumb") do
                image_tag(main_app.url_for(attachment.variant(resize_to_limit: [120, 80])), alt: "")
              end
              preview += content_tag(:div, class: "rp-image-section__info") do
                content_tag(:span, attachment.filename, class: "rp-image-section__filename") +
                content_tag(:span, number_to_human_size(attachment.byte_size), class: "rp-image-section__meta")
              end
              preview += content_tag(:div, class: "rp-image-section__actions") do
                content_tag(:label, class: "rp-btn rp-btn--outline rp-btn--sm") do
                  "Change".html_safe + form.file_field(name, accept: "image/*", class: "rp-sr-only", direct_upload: true)
                end
              end
              preview
            end
            output += rp_hint("Save to enable focal point editing.")
          else
            # No image - show dropzone
            output += render(partial: "railspress/admin/shared/dropzone",
                           locals: { form: form, field_name: name, prompt: "Click to upload #{label.downcase}" })
          end
          output
        end
      end
    end

    # ============================================================
    # TABLE ACTION HELPERS
    # ============================================================

    # Renders the standard edit icon button for table rows.
    # @param path [String] the edit path
    # @param title [String] tooltip text
    # @return [String] rendered HTML
    def rp_edit_icon(path, title: "Edit")
      link_to path, class: "rp-icon-btn", title: title do
        rp_icon(:edit)
      end
    end

    # Renders the standard delete icon button for table rows.
    # @param path [String] the delete path
    # @param confirm [String] confirmation message
    # @param title [String] tooltip text
    # @return [String] rendered HTML
    def rp_delete_icon(path, confirm: "Delete this item?", title: "Delete", disabled: false, disabled_title: nil)
      if disabled
        content_tag(:span, class: "rp-icon-btn rp-icon-btn--danger rp-icon-btn--disabled",
                           title: disabled_title || title) do
          rp_icon(:trash)
        end
      else
        button_to path, method: :delete,
          data: { turbo_confirm: confirm },
          class: "rp-icon-btn rp-icon-btn--danger", title: title do
          rp_icon(:trash)
        end
      end
    end

    # Renders standard edit and delete action icons for table rows.
    # @param edit_path [String] the edit path
    # @param delete_path [String] the delete path
    # @param confirm [String] confirmation message for delete
    # @return [String] rendered HTML
    #
    # @example Usage
    #   rp_table_actions(edit_admin_category_path(category), admin_category_path(category), confirm: "Delete this category?")
    def rp_table_action_icons(edit_path:, delete_path:, confirm: "Delete this item?",
                              delete_disabled: false, disabled_title: nil)
      rp_edit_icon(edit_path) +
        rp_delete_icon(delete_path, confirm: confirm,
                       disabled: delete_disabled, disabled_title: disabled_title)
    end

    # Renders an SVG icon.
    # @param name [Symbol] the icon name (:edit, :trash, :plus, :search)
    # @return [String] rendered SVG HTML
    def rp_icon(name)
      icons = {
        edit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>',
        trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>',
        plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>',
        search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>'
      }
      icons[name]&.html_safe || ""
    end

    # ============================================================
    # TABLE DISPLAY HELPERS
    # ============================================================

    # Truncates text with ellipsis, HTML-safe.
    # @param text [String] the text to truncate
    # @param length [Integer] maximum length
    # @return [String] truncated text
    def rp_truncated_text(text, length: 50)
      truncate(text.to_s, length: length)
    end

    # Shows a colored badge for status values.
    # @param value [String, Symbol] the status value
    # @param type [Symbol] badge type (:success, :warning, :danger, :default, or status name like :published, :draft)
    # @return [String] rendered HTML
    #
    # @example Usage
    #   rp_status_badge(post.status)
    #   rp_status_badge("Active", type: :success)
    def rp_status_badge(value, type: nil)
      type ||= value.to_s.downcase.to_sym
      rp_badge(value.to_s.titleize, status: type)
    end

    # Shows "Yes" / "No" badge with appropriate styling.
    # @param value [Boolean] the boolean value
    # @return [String] rendered HTML
    #
    # @example Usage
    #   rp_boolean_badge(post.featured)  # => green "Yes" or gray "No"
    def rp_boolean_badge(value)
      if value
        rp_badge("Yes", status: :published)
      else
        rp_badge("No", status: :draft)
      end
    end

    # Shows attachment status badge.
    # @param attachment [ActiveStorage::Attached] the attachment or attachments
    # @return [String] rendered HTML
    #
    # @example Usage
    #   rp_attachment_badge(post.header_image)  # => "Attached" or "None"
    #   rp_attachment_badge(project.gallery)    # => "5 images" or "None"
    def rp_attachment_badge(attachment)
      if attachment.respond_to?(:attached?) && attachment.attached?
        if attachment.respond_to?(:count)
          count = attachment.count
          rp_badge(pluralize(count, "file"), status: :published)
        else
          rp_badge("Attached", status: :published)
        end
      else
        rp_badge("None", status: :draft)
      end
    end

    # ============================================================
    # FLASH/FEEDBACK HELPERS
    # ============================================================

    # Renders all flash message types with appropriate styling.
    # @return [String] rendered HTML
    #
    # @example Usage (in layout)
    #   <%= rp_flash_messages %>
    def rp_flash_messages
      return unless flash.any?

      flash_type_classes = {
        notice: "rp-flash--success",
        alert: "rp-flash--danger",
        warning: "rp-flash--warning",
        info: "rp-flash--info"
      }

      content_tag(:div, class: "rp-flash-container") do
        flash.map do |type, message|
          css_class = flash_type_classes[type.to_sym] || "rp-flash--info"
          content_tag(:div, message, class: "rp-flash #{css_class}")
        end.join.html_safe
      end
    end

    # ============================================================
    # LAYOUT HELPERS (existing methods below)
    # ============================================================
    # Renders a page header with title and optional action buttons.
    # @param title [String] the page title
    # @param actions [Hash] action links to render (label => path or label => [path, options])
    # @return [String] rendered HTML
    #
    # @example Basic usage
    #   <%= rp_page_header "Posts" %>
    #
    # @example With primary action
    #   <%= rp_page_header "Posts", "New Post" => new_admin_post_path %>
    #
    # @example With multiple actions
    #   <%= rp_page_header "Posts",
    #     "Export" => [admin_exports_path, class: "rp-btn rp-btn--secondary"],
    #     "New Post" => new_admin_post_path %>
    def rp_page_header(title, actions = {})
      content_tag(:div, class: "rp-page-header") do
        header_content = content_tag(:h1, title, class: "rp-page-title")

        if actions.any?
          action_links = actions.map do |label, target|
            path, options = target.is_a?(Array) ? target : [target, {}]
            btn_class = options.delete(:class) || "rp-btn rp-btn--primary"
            link_to(label, path, options.merge(class: btn_class))
          end.join.html_safe

          header_content += content_tag(:div, action_links, class: "rp-page-actions")
        end

        header_content
      end
    end

    # Renders a standalone page title (for new/edit pages without actions).
    # @param title [String] the page title
    # @return [String] rendered HTML
    def rp_page_title(title)
      content_tag(:h1, title, class: "rp-page-title rp-page-title--standalone")
    end

    # Renders a card wrapper for content.
    # @param padded [Boolean] whether to add internal padding
    # @param options [Hash] additional HTML attributes
    # @yield the card content
    # @return [String] rendered HTML
    #
    # @example Basic card
    #   <%= rp_card do %>
    #     <table>...</table>
    #   <% end %>
    #
    # @example Padded card for forms
    #   <%= rp_card(padded: true) do %>
    #     <%= render "form" %>
    #   <% end %>
    def rp_card(padded: false, **options, &block)
      classes = ["rp-card"]
      classes << "rp-card--padded" if padded
      classes << options.delete(:class) if options[:class]

      content_tag(:div, options.merge(class: classes.join(" ")), &block)
    end

    # Renders form errors in the standard style.
    # @param record [ActiveRecord::Base] the record to check for errors
    # @return [String, nil] rendered HTML or nil if no errors
    def rp_form_errors(record)
      return unless record.errors.any?

      content_tag(:div, class: "rp-form-errors") do
        content_tag(:ul) do
          record.errors.full_messages.map do |msg|
            content_tag(:li, msg)
          end.join.html_safe
        end
      end
    end

    # Renders a form group (label + input wrapper) with consistent styling.
    # @yield the form group content (label and input)
    # @return [String] rendered HTML
    def rp_form_group(&block)
      content_tag(:div, class: "rp-form-group", &block)
    end

    # Renders form actions (submit + cancel) with consistent styling.
    # @param form [ActionView::Helpers::FormBuilder] the form builder
    # @param cancel_path [String] path for cancel link
    # @param submit_text [String] text for submit button (defaults to form default)
    # @return [String] rendered HTML
    def rp_form_actions(form, cancel_path, submit_text: nil)
      content_tag(:div, class: "rp-form-actions") do
        submit_options = { class: "rp-btn rp-btn--primary" }
        buttons = form.submit(submit_text, submit_options)
        buttons += link_to("Cancel", cancel_path, class: "rp-btn rp-btn--secondary")
        buttons
      end
    end

    # Renders a sidebar section for complex forms.
    # @param title [String] the section title
    # @yield the section content
    # @return [String] rendered HTML
    def rp_sidebar_section(title, &block)
      content_tag(:div, class: "rp-sidebar-section") do
        content_tag(:h3, title, class: "rp-sidebar-title") +
          capture(&block)
      end
    end

    # Renders an empty state message for lists with no items.
    # @param message [String] the message to display
    # @param link_text [String, nil] optional link text
    # @param link_path [String, nil] optional link path
    # @return [String] rendered HTML
    def rp_empty_state(message, link_text: nil, link_path: nil)
      content = message
      content += " " + link_to(link_text, link_path, class: "rp-link") + "." if link_text && link_path

      content_tag(:p, content.html_safe, class: "rp-empty-state")
    end

    # Renders a badge with the appropriate status styling.
    # @param text [String] the badge text
    # @param status [Symbol, String] the status type (:draft, :published, :pending, etc.)
    # @return [String] rendered HTML
    def rp_badge(text, status:)
      content_tag(:span, text, class: "rp-badge rp-badge--#{status}")
    end

    # Renders a hint/help text below a form input.
    # @param text [String] the hint text
    # @return [String] rendered HTML
    def rp_hint(text)
      content_tag(:p, text, class: "rp-hint")
    end

    # CSS classes for a standard text input.
    # @param primary [Boolean] whether this is the primary/title input
    # @param mono [Boolean] whether to use monospace font (for slugs, codes)
    # @param size [Symbol] input size (:sm, :lg, or nil for default)
    # @return [String] CSS class string
    def rp_input_class(primary: false, mono: false, size: nil)
      classes = ["rp-input"]
      classes << "rp-input--title" if primary
      classes << "rp-input--mono" if mono
      classes << "rp-input--#{size}" if size
      classes.join(" ")
    end

    # CSS classes for a label.
    # @param large [Boolean] whether to use large label style
    # @param required [Boolean] whether to show required indicator
    # @return [String] CSS class string
    def rp_label_class(large: false, required: false)
      classes = ["rp-label"]
      classes << "rp-label--lg" if large
      classes << "rp-label--required" if required
      classes.join(" ")
    end

    # Renders a sortable table header link.
    # Clicking toggles between ascending and descending order.
    # @param column [Symbol, String] the column name for sorting
    # @param label [String] the display text for the header
    # @param current_sort [String, nil] the currently sorted column
    # @param current_direction [String] current sort direction ("asc" or "desc")
    # @return [String] rendered HTML
    #
    # @example Basic usage
    #   <%= rp_sortable_header(:title, "Title", current_sort: @sort, current_direction: @direction) %>
    def rp_sortable_header(column, label, current_sort:, current_direction:)
      column = column.to_s
      is_active = current_sort == column
      # Toggle direction if clicking the same column, otherwise default to asc
      new_direction = is_active && current_direction == "asc" ? "desc" : "asc"

      classes = ["rp-sortable"]
      classes << "rp-sortable--active" if is_active
      classes << "rp-sortable--#{current_direction}" if is_active

      link_to(
        label,
        url_for(request.query_parameters.merge(sort: column, direction: new_direction)),
        class: classes.join(" ")
      )
    end

    # Renders a non-sortable table header.
    # @param label [String] the display text for the header
    # @param options [Hash] additional HTML attributes
    # @return [String] rendered HTML
    def rp_table_header(label, **options)
      content_tag(:span, label, options)
    end
  end
end
