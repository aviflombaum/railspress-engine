require "rails_helper"

RSpec.describe Railspress::ExportPostsJob, type: :job do
  fixtures "railspress/posts", "railspress/categories", "railspress/tags"

  describe "job enqueueing" do
    it "enqueues the job" do
      export = Railspress::Export.create!(export_type: "posts")
      expect {
        described_class.perform_later(export.id)
      }.to have_enqueued_job(described_class)
    end

    it "enqueues on default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end

    it "enqueues with correct arguments" do
      export = Railspress::Export.create!(export_type: "posts")
      expect {
        described_class.perform_later(export.id)
      }.to have_enqueued_job.with(export.id)
    end
  end

  describe "#perform" do
    let(:export) { Railspress::Export.create!(export_type: "posts") }

    before do
      # Ensure posts have content
      Railspress::Post.find_each do |post|
        post.update!(content: "<p>Content</p>") unless post.content.present?
      end
    end

    it "processes the export" do
      described_class.perform_now(export.id)
      expect(export.reload.completed?).to be true
    end

    it "attaches zip file to export" do
      described_class.perform_now(export.id)
      expect(export.reload.file).to be_attached
    end

    it "updates export counts" do
      described_class.perform_now(export.id)
      expect(export.reload.total_count).to eq(Railspress::Post.count)
      expect(export.reload.success_count).to eq(Railspress::Post.count)
    end

    context "when export fails" do
      it "marks export as failed and records error" do
        allow(Railspress::PostExportProcessor).to receive(:new).and_raise("Unexpected error")
        expect {
          described_class.perform_now(export.id)
        }.to raise_error("Unexpected error")
        expect(export.reload.failed?).to be true
      end
    end
  end
end
