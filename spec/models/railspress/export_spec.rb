require "rails_helper"

RSpec.describe Railspress::Export, type: :model do
  describe "validations" do
    it "requires export_type" do
      export = Railspress::Export.new(export_type: nil)
      expect(export).not_to be_valid
      expect(export.errors[:export_type]).to be_present
    end

    it "validates export_type inclusion" do
      export = Railspress::Export.new(export_type: "invalid")
      expect(export).not_to be_valid
    end

    it "validates status inclusion" do
      export = Railspress::Export.new(export_type: "posts", status: "invalid")
      expect(export).not_to be_valid
    end

    it "is valid with valid attributes" do
      export = Railspress::Export.new(export_type: "posts", status: "pending")
      expect(export).to be_valid
    end
  end

  describe "status methods" do
    let(:export) { Railspress::Export.create!(export_type: "posts", status: "pending") }

    it "#pending? returns true for pending exports" do
      expect(export.pending?).to be true
    end

    it "#processing? returns true for processing exports" do
      export.update!(status: "processing")
      expect(export.processing?).to be true
    end

    it "#completed? returns true for completed exports" do
      export.update!(status: "completed")
      expect(export.completed?).to be true
    end

    it "#failed? returns true for failed exports" do
      export.update!(status: "failed")
      expect(export.failed?).to be true
    end

    it "#mark_processing! updates status" do
      export.mark_processing!
      expect(export.reload.status).to eq("processing")
    end

    it "#mark_completed! updates status" do
      export.mark_completed!
      expect(export.reload.status).to eq("completed")
    end

    it "#mark_failed! updates status" do
      export.mark_failed!
      expect(export.reload.status).to eq("failed")
    end
  end

  describe "#add_error" do
    let(:export) { Railspress::Export.create!(export_type: "posts") }

    it "adds error message to error_messages" do
      export.add_error("Something went wrong")
      expect(export.parsed_errors).to include("Something went wrong")
    end

    it "increments error_count" do
      expect { export.add_error("Error") }.to change { export.reload.error_count }.by(1)
    end

    it "appends to existing errors" do
      export.add_error("First error")
      export.add_error("Second error")
      expect(export.parsed_errors.size).to eq(2)
    end
  end

  describe "#increment_success!" do
    it "increments success_count" do
      export = Railspress::Export.create!(export_type: "posts")
      expect { export.increment_success! }.to change { export.reload.success_count }.by(1)
    end
  end

  describe "#increment_total!" do
    it "increments total_count" do
      export = Railspress::Export.create!(export_type: "posts")
      expect { export.increment_total! }.to change { export.reload.total_count }.by(1)
    end
  end

  describe "scopes" do
    before do
      Railspress::Export.create!(export_type: "posts", status: "pending")
      Railspress::Export.create!(export_type: "posts", status: "completed")
      Railspress::Export.create!(export_type: "posts", status: "failed")
    end

    it "filters by type" do
      expect(Railspress::Export.by_type("posts").count).to eq(3)
    end

    it "filters pending exports" do
      expect(Railspress::Export.pending.count).to eq(1)
    end

    it "filters completed exports" do
      expect(Railspress::Export.completed.count).to eq(1)
    end

    it "filters failed exports" do
      expect(Railspress::Export.failed.count).to eq(1)
    end

    it "returns recent exports in descending order" do
      exports = Railspress::Export.recent
      expect(exports.first.created_at).to be >= exports.last.created_at
    end
  end
end
