require "rails_helper"

RSpec.describe Railspress::Import, type: :model do
  fixtures "railspress/imports"

  describe "validations" do
    it "requires import_type" do
      import = Railspress::Import.new(import_type: nil)
      expect(import).not_to be_valid
      expect(import.errors[:import_type]).to include("can't be blank")
    end

    it "validates import_type inclusion" do
      import = Railspress::Import.new(import_type: "invalid")
      expect(import).not_to be_valid
      expect(import.errors[:import_type]).to include("is not included in the list")
    end

    it "validates status inclusion" do
      import = Railspress::Import.new(import_type: "posts", status: "invalid")
      expect(import).not_to be_valid
      expect(import.errors[:status]).to include("is not included in the list")
    end

    it "is valid with valid attributes" do
      import = Railspress::Import.new(import_type: "posts")
      expect(import).to be_valid
    end
  end

  describe "scopes" do
    it "filters by type" do
      imports = Railspress::Import.by_type("posts")
      expect(imports).to all(have_attributes(import_type: "posts"))
    end

    it "returns recent imports in descending order" do
      imports = Railspress::Import.recent
      expect(imports.limit_value).to eq(10)
    end

    it "filters pending imports" do
      expect(Railspress::Import.pending).to include(railspress_imports(:pending_import))
    end

    it "filters completed imports" do
      expect(Railspress::Import.completed).to include(railspress_imports(:completed_import))
    end

    it "filters failed imports" do
      expect(Railspress::Import.failed).to include(railspress_imports(:failed_import))
    end
  end

  describe "status methods" do
    let(:import) { railspress_imports(:pending_import) }

    it "#mark_processing! updates status" do
      import.mark_processing!
      expect(import.status).to eq("processing")
    end

    it "#mark_completed! updates status" do
      import.mark_completed!
      expect(import.status).to eq("completed")
    end

    it "#mark_failed! updates status" do
      import.mark_failed!
      expect(import.status).to eq("failed")
    end

    it "#pending? returns true for pending imports" do
      expect(import.pending?).to be true
    end

    it "#processing? returns true for processing imports" do
      import.mark_processing!
      expect(import.processing?).to be true
    end

    it "#completed? returns true for completed imports" do
      expect(railspress_imports(:completed_import).completed?).to be true
    end

    it "#failed? returns true for failed imports" do
      expect(railspress_imports(:failed_import).failed?).to be true
    end
  end

  describe "#add_error" do
    let(:import) { railspress_imports(:pending_import) }

    it "adds error message to error_messages" do
      import.add_error("Something went wrong")
      expect(import.parsed_errors).to include("Something went wrong")
    end

    it "increments error_count" do
      import.add_error("Error 1")
      import.add_error("Error 2")
      expect(import.error_count).to eq(2)
    end

    it "appends to existing errors" do
      import.add_error("First error")
      import.add_error("Second error")
      expect(import.parsed_errors.size).to eq(2)
    end
  end

  describe "#parsed_errors" do
    it "returns empty array when no errors" do
      import = Railspress::Import.new(import_type: "posts")
      expect(import.parsed_errors).to eq([])
    end

    it "parses JSON error messages" do
      import = railspress_imports(:failed_import)
      expect(import.parsed_errors).to eq([ "post-1.md: Parse error", "post-2.md: No content" ])
    end
  end

  describe "#increment_success!" do
    let(:import) { railspress_imports(:pending_import) }

    it "increments success_count" do
      expect { import.increment_success! }.to change(import, :success_count).by(1)
    end
  end

  describe "#increment_total!" do
    let(:import) { railspress_imports(:pending_import) }

    it "increments total_count" do
      expect { import.increment_total! }.to change(import, :total_count).by(1)
    end
  end
end
