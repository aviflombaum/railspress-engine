module Railspress
  class ImportPostsJob < ApplicationJob
    queue_as :default

    def perform(import_id, file_paths)
      import = Import.find(import_id)
      paths = Array(file_paths)

      import.mark_processing!

      begin
        paths.each do |file_path|
          processor = PostImportProcessor.new(import: import, file_path: file_path)
          processor.process_file(file_path)
        end
      ensure
        finalize_import(import)
        cleanup_uploaded_files(paths)
      end
    end

    private

    def finalize_import(import)
      if import.error_count > 0 && import.success_count == 0
        import.mark_failed!
      else
        import.mark_completed!
      end
    end

    def cleanup_uploaded_files(file_paths)
      tmp_dir = Rails.root.join("tmp").to_s

      file_paths.each do |path|
        # Only cleanup files in the tmp directory to avoid deleting source files
        next unless path.start_with?(tmp_dir)
        FileUtils.rm_f(path) if File.exist?(path)
      end
    rescue => e
      Rails.logger.warn "Failed to cleanup uploaded import files: #{e.message}"
    end
  end
end
