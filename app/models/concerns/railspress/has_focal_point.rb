# frozen_string_literal: true

module Railspress::HasFocalPoint
  extend ActiveSupport::Concern

  class_methods do
    # Unified DSL for declaring an image attachment with focal point support
    #
    # One call that handles everything:
    # - has_one_attached with variant configuration
    # - has_focal_point for focal point editing
    # - railspress_fields registration (if Railspress::Entity included)
    #
    # @param attachment_name [Symbol] Name of the attachment
    # @yield [attachable] Optional block for ActiveStorage variant configuration
    #
    # @example Simple usage (no variants)
    #   focal_point_image :cover_image
    #
    # @example With variants
    #   focal_point_image :header_image do |attachable|
    #     attachable.variant :hero, resize_to_fill: [2100, 900, { crop: :centre }]
    #     attachable.variant :card, resize_to_fill: [800, 500, { crop: :centre }]
    #     attachable.variant :thumb, resize_to_fill: [400, 250, { crop: :centre }]
    #     attachable.variant :og, resize_to_fill: [1200, 630, { crop: :centre }]
    #   end
    #
    def focal_point_image(attachment_name, &block)
      # Declare the ActiveStorage attachment with optional variant block
      has_one_attached attachment_name, &block

      # Add focal point support
      has_focal_point attachment_name

      # Auto-register with Railspress entity system if available
      if respond_to?(:railspress_fields)
        railspress_fields attachment_name, as: :focal_point_image
      end
    end

    # Declare focal point support for an attachment
    #
    # Creates a polymorphic association to Railspress::FocalPoint.
    # No migration needed on the host model - data stored in railspress_focal_points table.
    #
    # @param attachment_name [Symbol] Name of the ActiveStorage attachment
    #
    # @example
    #   class Post < ApplicationRecord
    #     has_one_attached :header_image
    #     has_focal_point :header_image
    #   end
    #
    #   class Project < ApplicationRecord
    #     include Railspress::HasFocalPoint
    #     has_one_attached :cover_image
    #     has_focal_point :cover_image
    #   end
    #
    def has_focal_point(attachment_name)
      association_name = :"#{attachment_name}_focal_point"

      # Define the has_one association for this attachment's focal point
      has_one association_name,
              -> { where(attachment_name: attachment_name.to_s) },
              as: :record,
              class_name: "Railspress::FocalPoint",
              dependent: :destroy,
              autosave: true

      # Accept nested attributes for form integration
      accepts_nested_attributes_for association_name

      # Override the association reader to auto-build if nil
      define_method(association_name) do
        super() || send(:"build_#{association_name}", attachment_name: attachment_name.to_s)
      end

      # Auto-create focal point when image is attached
      after_commit :"ensure_#{attachment_name}_focal_point"

      define_method(:"ensure_#{attachment_name}_focal_point") do
        attachment = send(attachment_name)
        return unless attachment.attached?

        # Use the raw association to avoid auto-build, check if persisted
        existing = Railspress::FocalPoint.find_by(
          record_type: self.class.name,
          record_id: id,
          attachment_name: attachment_name.to_s
        )
        return if existing

        Railspress::FocalPoint.create!(
          record: self,
          attachment_name: attachment_name.to_s,
          focal_x: 0.5,
          focal_y: 0.5
        )
      end

      # Store attachment name for lookup
      @focal_point_attachments ||= []
      @focal_point_attachments << attachment_name
    end

    def focal_point_attachments
      @focal_point_attachments || []
    end
  end

  # Get focal point as hash
  #
  # @param attachment_name [Symbol] Attachment name
  # @return [Hash] { x: Float, y: Float }
  #
  def focal_point(attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.to_point
  end

  # Get CSS object-position value
  #
  # @param attachment_name [Symbol] Attachment name
  # @return [String] CSS property value
  #
  def focal_point_css(attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.to_css
  end

  # Check if focal point differs from center
  #
  def has_focal_point?(attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.offset_from_center?
  end

  # Get override for specific context
  #
  # @param context [Symbol, String] Context name (e.g., :hero, :card)
  # @param attachment_name [Symbol] Attachment name
  # @return [Hash, nil] Override data or nil
  #
  def image_override(context, attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.override_for(context)
  end

  # Check if context has custom override (not using focal point)
  #
  def has_image_override?(context, attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.has_override?(context)
  end

  # Set override for context
  #
  def set_image_override(context, data, attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.set_override(context, data)
  end

  # Clear override for context (revert to focal point)
  #
  def clear_image_override(context, attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.clear_override(context)
  end

  # Get the appropriate image for a context
  #
  # Returns the original attachment or a custom uploaded blob.
  # Host apps use this with standard Rails image_tag:
  #
  #   <%= image_tag @post.image_for(:hero), style: @post.image_css_for(:hero) %>
  #
  # @param context [Symbol, String] Context name (e.g., :hero, :card)
  # @param attachment_name [Symbol] Attachment name
  # @return [ActiveStorage::Attached, ActiveStorage::Blob] The image to display
  #
  def image_for(context, attachment_name = default_focal_attachment)
    override = image_override(context, attachment_name)

    if override&.dig(:type) == "upload" && override[:blob_signed_id].present?
      begin
        ActiveStorage::Blob.find_signed!(override[:blob_signed_id])
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
        send(attachment_name) # Fallback to original if blob not found
      end
    else
      send(attachment_name)
    end
  end

  # Get CSS for displaying image in a context
  #
  # Returns object-position CSS for focal point or crop region.
  # Host apps use this with standard Rails image_tag:
  #
  #   <%= image_tag @post.image_for(:hero), style: @post.image_css_for(:hero) %>
  #
  # @param context [Symbol, String] Context name (e.g., :hero, :card)
  # @param attachment_name [Symbol] Attachment name
  # @return [String] CSS property value(s)
  #
  def image_css_for(context, attachment_name = default_focal_attachment)
    override = image_override(context, attachment_name)

    case override&.dig(:type)
    when "crop"
      # Custom crop region - calculate center of crop for object-position
      region = override[:region]&.with_indifferent_access
      if region
        x_offset = (region[:x].to_f + region[:width].to_f / 2) * 100
        y_offset = (region[:y].to_f + region[:height].to_f / 2) * 100
        "object-position: #{x_offset.round(1)}% #{y_offset.round(1)}%"
      else
        focal_point_css(attachment_name)
      end
    when "upload"
      # Custom upload - center it (no focal point data for uploaded images)
      "object-position: 50% 50%"
    else
      # Default: use focal point
      focal_point_css(attachment_name)
    end
  end

  # Reset focal point to center
  #
  def reset_focal_point!(attachment_name = default_focal_attachment)
    fp = send(:"#{attachment_name}_focal_point")
    fp.reset!
  end

  private

  def default_focal_attachment
    self.class.focal_point_attachments.first || :header_image
  end
end
