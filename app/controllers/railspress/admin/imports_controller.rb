module Railspress
  module Admin
    class ImportsController < BaseController
      before_action :validate_import_type, only: [:show]

      def show
        @import_type = params[:type]
        @recent_imports = Import.by_type(@import_type).recent
      end

      def create
        uploaded_files = Array(import_params[:file]).reject(&:blank?)

        if uploaded_files.empty?
          redirect_to typed_admin_imports_path(type: import_params[:import_type]),
                      alert: "Please select at least one file to import."
          return
        end

        # Create import record
        import = Import.create!(
          import_type: import_params[:import_type],
          filename: uploaded_files.size == 1 ? uploaded_files.first.original_filename : "#{uploaded_files.size} files",
          content_type: uploaded_files.first.content_type,
          status: "pending"
        )

        # Save uploaded files to tmp
        file_paths = save_uploaded_files(import, uploaded_files)

        # Enqueue job
        ImportPostsJob.perform_later(import.id, file_paths)

        redirect_to typed_admin_imports_path(type: import_params[:import_type]),
                    notice: "Import started. #{uploaded_files.size} file(s) queued for processing."
      end

      private

      def validate_import_type
        unless Import::IMPORT_TYPES.include?(params[:type])
          redirect_to admin_root_path, alert: "Invalid import type."
        end
      end

      def import_params
        params.require(:import).permit(:import_type, file: [])
      end

      def save_uploaded_files(import, uploaded_files)
        upload_dir = Rails.root.join("tmp", "uploads", "import_#{import.id}")
        FileUtils.mkdir_p(upload_dir)

        uploaded_files.map do |file|
          path = upload_dir.join(file.original_filename)
          File.open(path, "wb") { |f| f.write(file.read) }
          path.to_s
        end
      end
    end
  end
end
