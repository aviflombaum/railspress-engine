module Railspress
  class ExportPostsJob < ApplicationJob
    queue_as :default

    def perform(export_id)
      export = Export.find(export_id)

      processor = PostExportProcessor.new(export: export)
      processor.process!
    rescue => e
      export.add_error("Export failed: #{e.message}")
      export.mark_failed!
      raise
    end
  end
end
