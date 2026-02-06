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
    # @param group [String] the content group name
    # @param name [String] the content element name
    # @param html_options [Hash] additional HTML options (for future inline editing)
    # @yield [value, element] optional block for custom rendering
    # @return [String] rendered content
    def cms_element(group:, name:, html_options: {}, &block)
      content_element = Railspress::CMS.find(group).load(name).element
      element_value = content_element&.value

      if content_element&.image? && content_element&.image&.attached?
        return image_tag(main_app.url_for(content_element.image), html_options)
      end

      if block_given?
        args = block.arity.zero? ? [] : [element_value, content_element]
        capture(*args, &block)
      else
        element_value
      end
    end

    # Return a new CMSQuery instance for chainable API in views.
    # @return [CMSQuery]
    def cms
      CmsHelper::CMSQuery.new
    end
  end

  # Global CMS module for chainable API access outside views.
  # Usage: Railspress::CMS.find("group").load("element").value
  module CMS
    def self.find(group_name)
      CmsHelper::CMSQuery.new.find(group_name)
    end
  end
end
