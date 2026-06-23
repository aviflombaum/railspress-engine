# frozen_string_literal: true

module Railspress
  # Chainable API for content element retrieval.
  #
  # Usage:
  #   Railspress::CMS.find("Homepage").load("Hero H1").value
  #   Railspress::CMS.find("Homepage").load("Hero H1").element
  module CMS
    class Query
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
        cached = CMS.cache[cache_key]
        return cached if cached

        group = Railspress::ContentGroup.active.find_by(name: @group_name)
        return nil unless group

        found = group.content_elements.active.find_by(name: @element_name)
        CMS.cache[cache_key] = found if found
        found
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def value
        element&.value
      end
    end

    def self.cache
      @cache ||= {}
    end

    def self.clear_cache
      @cache = {}
    end

    def self.find(group_name)
      unless Railspress.cms_enabled?
        raise Railspress::ConfigurationError,
          "CMS is not enabled. Add `config.enable_cms` to your Railspress initializer."
      end

      Query.new.find(group_name)
    end
  end
end
