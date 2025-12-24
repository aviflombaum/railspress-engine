module Railspress
  module Admin
    class ExportsController < BaseController
      before_action :validate_export_type, only: [:show]
      before_action :set_export, only: [:download]

      def show
        @export_type = params[:type]
        @recent_exports = Export.by_type(@export_type).recent
        @post_count = Post.count
      end

      def create
        export = Export.create!(
          export_type: export_params[:export_type],
          status: "pending"
        )

        ExportPostsJob.perform_later(export.id)

        redirect_to typed_admin_exports_path(type: export_params[:export_type]),
                    notice: "Export started. You'll be able to download the file once processing completes."
      end

      def download
        if @export.file.attached?
          send_data @export.file.download,
                    filename: @export.filename,
                    type: "application/zip",
                    disposition: "attachment"
        else
          redirect_to typed_admin_exports_path(type: @export.export_type),
                      alert: "Export file not available."
        end
      end

      private

      def validate_export_type
        unless Export::EXPORT_TYPES.include?(params[:type])
          redirect_to admin_root_path, alert: "Invalid export type."
        end
      end

      def set_export
        @export = Export.find(params[:id])
      end

      def export_params
        params.require(:export).permit(:export_type)
      end
    end
  end
end
