# frozen_string_literal: true

module Railspress
  module Admin
    class CmsTransfersController < BaseController
      def show
        load_content_summary
      end

      def export
        result = ContentExportService.new.call

        send_data result.zip_data,
                  filename: result.filename,
                  type: "application/zip",
                  disposition: "attachment"
      end

      def import
        if params[:file].blank?
          redirect_to admin_cms_transfer_path, alert: "Please select a ZIP file to import."
          return
        end

        @result = ContentImportService.new(params[:file]).call
        load_content_summary

        if @result.errors.any?
          flash.now[:alert] = "Import completed with #{@result.errors.size} error(s)."
        else
          flash.now[:notice] = "Import successful! #{@result.total_processed} items processed."
        end

        render :show
      rescue ArgumentError => e
        redirect_to admin_cms_transfer_path, alert: e.message
      end

      private

      def load_content_summary
        @groups = ContentGroup.active.includes(:content_elements).order(:name)
        @group_count = @groups.size
        @element_count = ContentElement.active.count
        @image_count = ContentElement.active.image.count
      end
    end
  end
end
