# frozen_string_literal: true

module Railspress
  class FocalPoint < ApplicationRecord
    belongs_to :record, polymorphic: true

    validates :attachment_name, presence: true
    validates :focal_x, :focal_y,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

    validate :validate_overrides_structure

    # Valid override types
    VALID_OVERRIDE_TYPES = %w[focal crop upload].freeze

    # Get focal point as hash
    def to_point
      { x: focal_x, y: focal_y }
    end

    # Get CSS object-position value
    def to_css
      "object-position: #{(focal_x * 100).round(1)}% #{(focal_y * 100).round(1)}%"
    end

    # Check if focal point differs from center
    def offset_from_center?
      (focal_x - 0.5).abs > 0.001 || (focal_y - 0.5).abs > 0.001
    end

    # Get override for specific context
    def override_for(context)
      overrides[context.to_s]&.with_indifferent_access
    end

    # Check if context has custom override (not using focal point)
    def has_override?(context)
      override = override_for(context)
      override.present? && override[:type] != "focal"
    end

    # Set override for context
    def set_override(context, data)
      self.overrides = (overrides || {}).merge(context.to_s => data)
    end

    # Clear override for context (revert to focal point)
    def clear_override(context)
      set_override(context, { "type" => "focal" })
    end

    # Reset to center
    def reset!
      update!(focal_x: 0.5, focal_y: 0.5)
    end

    private

    def validate_overrides_structure
      return if overrides.blank?

      overrides.each do |context, override|
        next if override.blank?
        unless VALID_OVERRIDE_TYPES.include?(override["type"])
          errors.add(:overrides, "has invalid type for context #{context}")
        end
      end
    end
  end
end
