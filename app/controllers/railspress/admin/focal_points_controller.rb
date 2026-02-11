# frozen_string_literal: true

module Railspress
  module Admin
    class FocalPointsController < BaseController
      before_action :set_focal_point

      # PATCH /admin/focal_points/:id
      # Handles focal point updates, image changes, and image removal
      def update
        image_changed = false
        image_removed = false

        # Handle image removal
        if params[:remove_image] == "1"
          @record.send(@attachment_name).purge
          image_removed = true
        # Handle image change (only if not removing)
        elsif params[:image].present?
          @record.send("#{@attachment_name}=", params[:image])
          if @record.save
            image_changed = true
          else
            return render_error(@record.errors.full_messages.join(", "))
          end
        end

        # If image was changed or removed, redirect to refresh the page
        if image_changed || image_removed
          return redirect_to_record(notice: image_removed ? "Image removed" : "Image updated")
        end

        # Otherwise, update focal point and return turbo frame
        if @focal_point.update(focal_point_params)
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                helpers.dom_id(@record, "image_section_#{@attachment_name}"),
                partial: "railspress/admin/shared/image_section_compact",
                locals: {
                  record: @record,
                  attachment_name: @attachment_name.to_sym,
                  flash_message: "Focal point saved"
                }
              )
            end
            format.html do
              redirect_to_record(notice: "Focal point saved")
            end
          end
        else
          render_error(@focal_point.errors.full_messages.join(", "))
        end
      end

      private

      def set_focal_point
        @focal_point = FocalPoint.find(params[:id])
        @record = @focal_point.record
        @attachment_name = @focal_point.attachment_name
      end

      def focal_point_params
        params.require(:focal_point).permit(:focal_x, :focal_y, :overrides)
      end

      def redirect_to_record(notice: nil)
        path = if @record.is_a?(Railspress::Post)
          edit_admin_post_path(@record)
        elsif @record.is_a?(Railspress::ContentElement)
          edit_admin_content_element_path(@record)
        else
          entity_type = @record.class.railspress_config.route_key
          admin_edit_entity_path(entity_type: entity_type, id: @record.id)
        end
        redirect_to path, notice: notice
      end

      def render_error(message)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              helpers.dom_id(@record, "image_section_#{@attachment_name}"),
              partial: "railspress/admin/shared/image_section_editor",
              locals: {
                record: @record,
                attachment_name: @attachment_name.to_sym,
                error_message: message
              }
            )
          end
          format.html do
            redirect_to_record(notice: message)
          end
        end
      end
    end
  end
end
