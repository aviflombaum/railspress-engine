# frozen_string_literal: true

module Railspress
  # Stores field configuration for a single entity
  #
  # Stores class name as string for Rails reloader compatibility.
  # Class is resolved lazily via constantize on each access, ensuring
  # fresh class reference after code reload in development.
  class EntityConfig
    attr_writer :label

    def initialize(model_class_name)
      @model_class_name = model_class_name.to_s
      @field_definitions = {}
      @label = nil # Resolved lazily from model_class if not set
      @types_resolved = false
    end

    # Lazily resolve class - gets fresh class after Rails reload
    def model_class
      @model_class_name.constantize
    end

    def add_field(name, options = {})
      # Store the explicit type or mark for lazy detection
      explicit_type = options[:as]
      @field_definitions[name.to_sym] = {
        type: explicit_type,
        options: options.except(:as),
        needs_detection: explicit_type.nil?
      }
    end

    # Access fields with resolved types (lazy resolution)
    def fields
      resolve_field_types! unless @types_resolved
      @field_definitions
    end

    def route_key
      model_class.model_name.plural
    end

    def param_key
      model_class.model_name.param_key
    end

    def singular_label
      (label || model_class.model_name.human.pluralize).singularize
    end

    def label
      @label || model_class.model_name.human.pluralize
    end

    private

    def resolve_field_types!
      @field_definitions.each do |name, field|
        if field[:needs_detection]
          field[:type] = detect_type(name)
          field.delete(:needs_detection)
        end
      end
      @types_resolved = true
    end

    def detect_type(name)
      name_str = name.to_s

      # Check for ActionText rich text (has_one :rich_text_#{name} association)
      if model_class.reflect_on_association(:"rich_text_#{name_str}")
        return :rich_text
      end

      # Check for ActiveStorage attachments
      if model_class.respond_to?(:reflect_on_all_attachments)
        attachment = model_class.reflect_on_all_attachments.find do |a|
          a.name.to_s == name_str
        end
        if attachment
          return attachment.macro == :has_many_attached ? :attachments : :attachment
        end
      end

      # Check column type from schema
      column = model_class.columns_hash[name_str]
      return :string unless column

      case column.type
      when :text then :text
      when :integer then :integer
      when :boolean then :boolean
      when :datetime then :datetime
      when :date then :date
      when :decimal, :float then :decimal
      else :string
      end
    end
  end

  # Concern to include in host models for CMS management
  module Entity
    extend ActiveSupport::Concern

    included do
      class_attribute :_railspress_config, instance_writer: false
      # Store class name (string) for Rails reloader compatibility
      self._railspress_config = EntityConfig.new(self.name)

      # Default scopes available to all entities
      scope :ordered, -> { order(created_at: :desc) }
      scope :recent, -> { ordered.limit(10) }
    end

    # Default pagination - can be overridden in model
    PER_PAGE = 20

    class_methods do
      # Simple pagination for index views
      def page(page_number)
        page_number = [page_number.to_i, 1].max
        offset((page_number - 1) * per_page_count).limit(per_page_count)
      end

      # Allow models to override PER_PAGE
      def per_page_count
        const_defined?(:PER_PAGE, false) ? const_get(:PER_PAGE) : Railspress::Entity::PER_PAGE
      end

      # Declare which fields should appear in the CMS
      #
      # @example Simple field list (types auto-detected from schema)
      #   railspress_fields :title, :description, :published
      #
      # @example With explicit type override
      #   railspress_fields :body, as: :rich_text
      #
      # @example Hash syntax for multiple typed fields
      #   railspress_fields title: :string, body: :rich_text
      #
      def railspress_fields(*names, **options)
        # Handle positional args: railspress_fields :title, :description
        if options[:as] && names.length == 1
          # Single field with type: railspress_fields :body, as: :rich_text
          _railspress_config.add_field(names.first, as: options[:as])
        elsif names.any?
          # Multiple fields, auto-detect types
          names.each do |name|
            _railspress_config.add_field(name)
          end
        end

        # Handle hash syntax: railspress_fields title: :string, body: :rich_text
        options.except(:as).each do |name, type|
          _railspress_config.add_field(name, as: type)
        end
      end

      # Set custom label for sidebar/headers
      #
      # @example
      #   railspress_label "Client Projects"
      #
      def railspress_label(label)
        _railspress_config.label = label
      end

      # Access the entity configuration
      def railspress_config
        _railspress_config
      end
    end
  end
end
