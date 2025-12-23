require "rails_helper"

RSpec.describe Railspress::ImportPostsJob, type: :job do
  include ActiveJob::TestHelper

  fixtures "railspress/imports", "railspress/categories", "railspress/tags"

  let(:import) { railspress_imports(:pending_import) }
  let(:fixtures_path) { Rails.root.join("../../spec/fixtures/files") }

  describe "#perform" do
    context "with a single markdown file" do
      let(:file_path) { fixtures_path.join("valid_post.md").to_s }

      it "processes the file and creates a post" do
        expect {
          described_class.perform_now(import.id, file_path)
        }.to change(Railspress::Post, :count).by(1)
      end

      it "marks import as completed" do
        described_class.perform_now(import.id, file_path)
        expect(import.reload.status).to eq("completed")
      end

      it "updates import counts" do
        described_class.perform_now(import.id, file_path)
        expect(import.reload.success_count).to eq(1)
        expect(import.reload.total_count).to eq(1)
      end
    end

    context "with multiple files" do
      let(:file_paths) do
        [
          fixtures_path.join("valid_post.md").to_s,
          fixtures_path.join("minimal_post.md").to_s
        ]
      end

      it "processes all files" do
        expect {
          described_class.perform_now(import.id, file_paths)
        }.to change(Railspress::Post, :count).by(2)
      end

      it "tracks counts for all files" do
        described_class.perform_now(import.id, file_paths)
        expect(import.reload.total_count).to eq(2)
        expect(import.reload.success_count).to eq(2)
      end
    end

    context "with a zip file" do
      let(:file_path) { fixtures_path.join("posts_import.zip").to_s }

      it "extracts and processes all files from zip" do
        expect {
          described_class.perform_now(import.id, file_path)
        }.to change(Railspress::Post, :count).by(4)
      end

      it "marks import as completed" do
        described_class.perform_now(import.id, file_path)
        expect(import.reload.status).to eq("completed")
      end
    end

    context "with mixed success and failure" do
      let(:file_paths) do
        [
          fixtures_path.join("valid_post.md").to_s,
          fixtures_path.join("invalid_frontmatter.md").to_s
        ]
      end

      it "still marks as completed if at least one succeeds" do
        described_class.perform_now(import.id, file_paths)
        expect(import.reload.status).to eq("completed")
      end

      it "tracks both successes and errors" do
        described_class.perform_now(import.id, file_paths)
        expect(import.reload.success_count).to eq(1)
        expect(import.reload.error_count).to eq(1)
      end
    end

    context "with all failures" do
      let(:file_paths) do
        [fixtures_path.join("invalid_frontmatter.md").to_s]
      end

      it "marks import as failed" do
        described_class.perform_now(import.id, file_paths)
        expect(import.reload.status).to eq("failed")
      end
    end
  end

  describe "job enqueueing" do
    let(:file_path) { fixtures_path.join("valid_post.md").to_s }

    it "enqueues the job" do
      expect {
        described_class.perform_later(import.id, file_path)
      }.to have_enqueued_job(described_class)
    end

    it "enqueues with correct arguments" do
      expect {
        described_class.perform_later(import.id, file_path)
      }.to have_enqueued_job.with(import.id, file_path)
    end

    it "enqueues on default queue" do
      expect {
        described_class.perform_later(import.id, file_path)
      }.to have_enqueued_job.on_queue("default")
    end
  end
end
