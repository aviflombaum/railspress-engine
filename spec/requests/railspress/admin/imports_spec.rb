# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Railspress::Admin::Imports", type: :request do
  describe "POST /admin/imports" do
    it "stores an upload under a server-generated filename" do
      generated_basename = "a" * 32
      allow(SecureRandom).to receive(:hex).with(16).and_return(generated_basename)
      source = Tempfile.new([ "post-import", ".md" ])
      source.write("# Imported post")
      source.rewind

      Dir.mktmpdir do |external_dir|
        requested_path = Pathname(external_dir).join("client-selected.md")
        upload = Rack::Test::UploadedFile.new(
          source.path,
          "text/markdown",
          false,
          original_filename: requested_path.to_s
        )

        post railspress.admin_imports_path,
             params: { import: { import_type: "posts", file: [ upload ] } }

        import = Railspress::Import.order(:id).last
        upload_dir = Rails.root.join("tmp", "uploads", "import_#{import.id}")
        stored_path = upload_dir.join("#{generated_basename}.md")

        expect(requested_path).not_to exist
        expect(stored_path).to exist
        expect(stored_path.read).to eq("# Imported post")
      ensure
        FileUtils.rm_rf(upload_dir) if upload_dir
      end
    ensure
      source&.close!
    end
  end
end
