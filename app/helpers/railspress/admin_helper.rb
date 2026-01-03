module Railspress
  # Helper methods for building consistent admin views.
  # Use these helpers to ensure styling consistency across all entity views.
  module AdminHelper
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
  end
end
