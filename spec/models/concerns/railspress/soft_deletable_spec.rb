# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::SoftDeletable, type: :model do
  # Test using ContentGroup which includes SoftDeletable
  # Use footers group (not headers, which has required elements that block soft_delete)
  fixtures "railspress/content_groups"

  let(:group) { railspress_content_groups(:footers) }
  let(:deleted_group) { railspress_content_groups(:deleted_group) }

  describe "#deleted?" do
    it "returns false for active records" do
      expect(group.deleted?).to be false
    end

    it "returns true for soft-deleted records" do
      expect(deleted_group.deleted?).to be true
    end
  end

  describe "#soft_delete" do
    it "sets deleted_at timestamp" do
      expect { group.soft_delete }.to change { group.reload.deleted_at }.from(nil)
    end

    it "does not destroy the record" do
      expect { group.soft_delete }.not_to change(Railspress::ContentGroup, :count)
    end
  end

  describe "#restore" do
    it "clears deleted_at timestamp" do
      expect { deleted_group.restore }.to change { deleted_group.reload.deleted_at }.to(nil)
    end
  end

  describe ".active" do
    it "excludes soft-deleted records" do
      expect(Railspress::ContentGroup.active).not_to include(deleted_group)
    end

    it "includes non-deleted records" do
      expect(Railspress::ContentGroup.active).to include(group)
    end
  end
end
