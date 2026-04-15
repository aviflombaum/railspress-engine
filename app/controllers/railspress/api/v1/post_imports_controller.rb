# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostImportsController < BaseController
        SUPPORTED_EXTENSIONS = %w[.md .markdown .txt .zip].freeze

        before_action :set_import, only: [ :show ]

        def create
          source = import_source
          return render_error("Either file or signed_blob_id is required.", status: :unprocessable_content) unless source

          unless supported_file?(source[:filename])
            return render_error("Unsupported import file type. Allowed: .md, .markdown, .txt, .zip.", status: :unprocessable_content)
          end

          import = Railspress::Import.create!(
            import_type: "posts",
            filename: source[:filename],
            content_type: source[:content_type],
            status: "pending",
            user_id: current_api_key&.owner_id
          )

          file_path = persist_import_file(import, source)
          Railspress::ImportPostsJob.perform_later(import.id, [ file_path ])

          render json: { data: serialize_import(import.reload) }, status: :accepted
        rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
          render_error("Invalid signed blob id.", status: :unprocessable_content)
        rescue => error
          Rails.logger.warn("Failed to create post import via API: #{error.class} #{error.message}")
          render_error("Failed to queue import.", status: :unprocessable_content)
        end

        def show
          render json: { data: serialize_import(@import) }
        end

        private

        def set_import
          @import = Railspress::Import.where(import_type: "posts").find(params[:id])
        end

        def import_source
          upload = params[:file] || params.dig(:import, :file)
          return upload_source(upload) if upload.present?

          signed_blob_id = params[:signed_blob_id] || params.dig(:import, :signed_blob_id)
          return nil if signed_blob_id.blank?

          blob_source(ActiveStorage::Blob.find_signed!(signed_blob_id))
        end

        def upload_source(upload)
          {
            type: :upload,
            value: upload,
            filename: upload.original_filename,
            content_type: upload.content_type
          }
        end

        def blob_source(blob)
          {
            type: :blob,
            value: blob,
            filename: blob.filename.to_s,
            content_type: blob.content_type
          }
        end

        def supported_file?(filename)
          extension = File.extname(filename.to_s).downcase
          SUPPORTED_EXTENSIONS.include?(extension)
        end

        def persist_import_file(import, source)
          upload_dir = Rails.root.join("tmp", "uploads", "import_#{import.id}")
          FileUtils.mkdir_p(upload_dir)

          filename = File.basename(source[:filename].to_s)
          destination = upload_dir.join(filename)

          case source[:type]
          when :upload
            FileUtils.cp(source[:value].path, destination)
          when :blob
            source[:value].open do |file|
              FileUtils.cp(file.path, destination)
            end
          end

          destination.to_s
        end

        def serialize_import(import)
          {
            id: import.id,
            import_type: import.import_type,
            filename: import.filename,
            content_type: import.content_type,
            status: import.status,
            total_count: import.total_count,
            success_count: import.success_count,
            error_count: import.error_count,
            error_messages: import.parsed_errors,
            created_at: import.created_at,
            updated_at: import.updated_at
          }
        end
      end
    end
  end
end
