# frozen_string_literal: true

module Railspress
  # CMS Helper provides a clean API for loading content elements in views.
  #
  # Usage in views:
  #   <%= cms_value("Homepage", "Hero H1") %>
  #
  #   <%= cms_element(group: "Homepage", name: "Hero H1") do |value| %>
  #     <h1><%= value %></h1>
  #   <% end %>
  #
  # Chainable API (works in controllers, services, etc.):
  #   Railspress::CMS.find("Homepage").load("Hero H1").value
  #   Railspress::CMS.find("Homepage").load("Hero H1").element
  #
  module CmsHelper
    # Stub module included when CMS is disabled.
    # Raises a descriptive error instead of NoMethodError.
    module DisabledStub
      def cms_element(*)
        raise Railspress::ConfigurationError,
          "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer."
      end

      def cms_value(*)
        raise Railspress::ConfigurationError,
          "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer."
      end
    end

    # Request-level cache to avoid repeated queries
    def self.cache
      @cache ||= {}
    end

    def self.clear_cache
      @cache = {}
    end

    # Chainable query class for content retrieval
    class CMSQuery
      def initialize
        @group_name = nil
        @element_name = nil
      end

      def find(group_name)
        @group_name = group_name
        self
      end

      def load(element_name)
        @element_name = element_name
        self
      end

      def element
        return nil unless @group_name && @element_name

        cache_key = "#{@group_name}:#{@element_name}"
        cached = CmsHelper.cache[cache_key]
        return cached if cached

        group = Railspress::ContentGroup.active.find_by(name: @group_name)
        return nil unless group

        found = group.content_elements.active.find_by(name: @element_name)
        CmsHelper.cache[cache_key] = found if found
        found
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def value
        element&.value
      end
    end

    # Get a content element's value by group and element name.
    # @param group_name [String] the content group name
    # @param element_name [String] the content element name
    # @return [String, nil] the element value or nil
    def cms_value(group_name, element_name)
      Railspress::CMS.find(group_name).load(element_name).value
    end

    # Render a content element, optionally with a block for custom rendering.
    # When inline editing is enabled, wraps content in a Stimulus-controlled
    # <span> with context menu and Turbo Frame markup for right-click editing.
    #
    # @param group [String] the content group name
    # @param name [String] the content element name
    # @param html_options [Hash] additional HTML options
    # @yield [value, element] optional block for custom rendering
    # @return [String] rendered content
    def cms_element(group:, name:, html_options: {}, &block)
      content_element = Railspress::CMS.find(group).load(name).element
      element_value = content_element&.value

      if content_element&.image? && content_element&.image&.attached?
        img_options = html_options.dup
        if content_element.has_focal_point?(:image)
          focal_css = content_element.focal_point_css(:image)
          existing_style = img_options[:style].to_s
          img_options[:style] = [existing_style, focal_css].reject(&:blank?).join("; ")
        end
        img_options[:alt] ||= content_element.name
        return image_tag(main_app.url_for(content_element.image), img_options)
      end

      rendered = if block_given?
        args = block.arity.zero? ? [] : [element_value, content_element]
        capture(*args, &block)
      else
        element_value
      end

      if content_element && !content_element.image? && inline_editor_enabled?
        inline_wrapper_for(content_element, rendered)
      else
        rendered
      end
    end

    # Check if inline editing is enabled for the current request.
    # Uses the configured inline_editing_check proc.
    # @return [Boolean]
    def inline_editor_enabled?
      check = Railspress.inline_editing_check
      return false unless check

      check.call(self)
    rescue
      false
    end

    # Render the display content within a Turbo Frame for inline replacement.
    # Used by the controller to replace display content after inline save.
    # @param content_element [ContentElement] the element
    # @param display_frame_id [String] the Turbo Frame ID
    # @return [String] HTML safe turbo-frame wrapped content
    def cms_element_display_frame(content_element, display_frame_id)
      content_tag("turbo-frame", content_element.value, id: display_frame_id)
    end

    # Return a new CMSQuery instance for chainable API in views.
    # @return [CMSQuery]
    def cms
      CmsHelper::CMSQuery.new
    end

    private

    # Wrap content in a Stimulus-controlled <span> for inline editing.
    # Includes a display Turbo Frame, hidden context menu with form Turbo Frame,
    # and hidden backdrop.
    def inline_wrapper_for(content_element, rendered_content)
      suffix = SecureRandom.hex(4)
      display_frame_id = "cms_display_#{content_element.id}_#{suffix}"
      form_frame_id = "cms_form_#{content_element.id}_#{suffix}"

      inline_path = railspress.inline_admin_content_element_path(content_element)
      update_path = railspress.admin_content_element_path(content_element)

      inject_inline_styles

      content_tag(:span,
        data: {
          controller: "rp--cms-inline-editor",
          "rp--cms-inline-editor-inline-path-value": inline_path,
          "rp--cms-inline-editor-update-path-value": update_path,
          "rp--cms-inline-editor-frame-id-value": display_frame_id,
          "rp--cms-inline-editor-form-frame-id-value": form_frame_id,
          "rp--cms-inline-editor-element-id-value": content_element.id,
          action: "contextmenu->rp--cms-inline-editor#open"
        },
        style: "display:contents"
      ) do
        # Display frame (replaced after save)
        display = content_tag("turbo-frame", rendered_content, id: display_frame_id)

        # Context menu panel (hidden by default)
        menu = content_tag(:div, class: "rp-inline-menu rp-inline-hidden",
          data: { "rp--cms-inline-editor-target": "menu" }
        ) do
          # Form Turbo Frame (lazy-loaded on first open)
          content_tag("turbo-frame", "", id: form_frame_id,
            src: nil,
            data: { "rp--cms-inline-editor-target": "frame" })
        end

        # Backdrop (hidden by default)
        backdrop = content_tag(:div, "", class: "rp-inline-backdrop rp-inline-hidden",
          data: {
            "rp--cms-inline-editor-target": "backdrop",
            action: "click->rp--cms-inline-editor#close"
          })

        safe_join([display, menu, backdrop])
      end
    end

    # Inject the inline editor CSS <style> tag once per page.
    def inject_inline_styles
      return if @_rp_inline_styles_injected
      @_rp_inline_styles_injected = true

      content_for :head, inline_editor_style_tag
    end

    def inline_editor_style_tag
      content_tag(:style, INLINE_EDITOR_CSS.html_safe, data: { rp_inline_styles: true })
    end

    INLINE_EDITOR_CSS = <<~CSS
      [data-controller="rp--cms-inline-editor"]:hover {
        outline: 2px dashed rgba(59, 130, 246, 0.5);
        outline-offset: 2px;
        cursor: context-menu;
      }
      .rp-inline-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.15);
        z-index: 9998;
      }
      .rp-inline-menu {
        position: fixed;
        z-index: 9999;
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
        width: 380px;
        max-height: 80vh;
        overflow-y: auto;
        padding: 1rem;
      }
      .rp-inline-hidden { display: none !important; }
      .rp-inline-meta {
        display: flex;
        gap: 0.5rem;
        align-items: center;
        margin-bottom: 0.75rem;
        font-size: 0.75rem;
      }
      .rp-inline-meta__group {
        background: #e0e7ff;
        color: #3730a3;
        padding: 0.15rem 0.5rem;
        border-radius: 4px;
        font-weight: 600;
      }
      .rp-inline-meta__name {
        color: #374151;
        font-weight: 500;
      }
      .rp-inline-meta__version {
        color: #9ca3af;
        margin-left: auto;
      }
      .rp-inline-errors {
        background: #fef2f2;
        border: 1px solid #fecaca;
        border-radius: 4px;
        padding: 0.5rem 0.75rem;
        margin-bottom: 0.75rem;
        font-size: 0.8rem;
        color: #991b1b;
      }
      .rp-inline-errors p { margin: 0; }
      .rp-inline-form__textarea {
        width: 100%;
        min-height: 80px;
        padding: 0.5rem;
        border: 1px solid #d1d5db;
        border-radius: 6px;
        font-family: inherit;
        font-size: 0.875rem;
        line-height: 1.5;
        resize: vertical;
        box-sizing: border-box;
      }
      .rp-inline-form__textarea:focus {
        outline: none;
        border-color: #3b82f6;
        box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.25);
      }
      .rp-inline-actions {
        display: flex;
        gap: 0.5rem;
        align-items: center;
        margin-top: 0.75rem;
      }
      .rp-inline-actions__save {
        padding: 0.4rem 1rem;
        background: #3b82f6;
        color: #fff;
        border: none;
        border-radius: 5px;
        font-size: 0.8rem;
        font-weight: 500;
        cursor: pointer;
      }
      .rp-inline-actions__save:hover { background: #2563eb; }
      .rp-inline-actions__cancel {
        padding: 0.4rem 1rem;
        background: #f3f4f6;
        color: #374151;
        border: 1px solid #d1d5db;
        border-radius: 5px;
        font-size: 0.8rem;
        cursor: pointer;
      }
      .rp-inline-actions__cancel:hover { background: #e5e7eb; }
      .rp-inline-actions__admin-link {
        margin-left: auto;
        font-size: 0.75rem;
        color: #6b7280;
        text-decoration: none;
      }
      .rp-inline-actions__admin-link:hover { color: #3b82f6; }
    CSS
  end

  # Global CMS module for chainable API access outside views.
  # Usage: Railspress::CMS.find("group").load("element").value
  module CMS
    def self.find(group_name)
      unless Railspress.cms_enabled?
        raise Railspress::ConfigurationError,
          "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer."
      end
      CmsHelper::CMSQuery.new.find(group_name)
    end
  end
end
