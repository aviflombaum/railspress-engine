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
      tmp_dir = File.realpath(Rails.root.join("tmp"))

      file_paths.each do |path|
        next unless File.exist?(path)

        resolved_path = File.realpath(path)
        next unless resolved_path.start_with?("#{tmp_dir}#{File::SEPARATOR}")

        FileUtils.rm_f(resolved_path)
      end
    rescue => e
      Rails.logger.warn "Failed to cleanup uploaded import files: #{e.message}"
    end
  end
end
