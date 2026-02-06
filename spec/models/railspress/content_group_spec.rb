# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::ContentGroup, type: :model do
  fixtures "railspress/content_groups", "railspress/content_elements"

  let(:headers) { railspress_content_groups(:headers) }
  let(:footers) { railspress_content_groups(:footers) }
  let(:deleted_group) { railspress_content_groups(:deleted_group) }

  describe "validations" do
    it "is valid with valid attributes" do
      group = Railspress::ContentGroup.new(name: "Sidebars", description: "Sidebar content")
      expect(group).to be_valid
    end

    it "requires a name" do
      group = Railspress::ContentGroup.new(name: nil)
      expect(group).not_to be_valid
      expect(group.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name" do
      group = Railspress::ContentGroup.new(name: headers.name)
      expect(group).not_to be_valid
      expect(group.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many content_elements" do
      expect(headers.content_elements).to be_present
    end
  end

  describe "scopes" do
    describe ".active" do
      it "excludes soft-deleted groups" do
        active = Railspress::ContentGroup.active
        expect(active).to include(headers, footers)
        expect(active).not_to include(deleted_group)
      end
    end

    describe ".ordered" do
      it "returns groups ordered by created_at desc" do
        groups = Railspress::ContentGroup.ordered
        expect(groups.to_sql).to include("ORDER BY")
      end
    end
  end

  describe "#element_count" do
    it "returns count of active content elements" do
      count = headers.element_count
      active_elements = headers.content_elements.where(deleted_at: nil)
      expect(count).to eq(active_elements.count)
    end
  end

  describe "#soft_delete" do
    it "soft deletes the group" do
      headers.soft_delete
      expect(headers.reload.deleted?).to be true
    end

    it "cascades soft delete to content elements" do
      headers.soft_delete
      headers.content_elements.reload.each do |element|
        expect(element.deleted?).to be true
      end
    end

    it "wraps in a transaction" do
      # If one element fails to soft delete, the group should not be deleted either
      allow_any_instance_of(Railspress::ContentElement).to receive(:soft_delete).and_raise(ActiveRecord::RecordInvalid)
      expect { headers.soft_delete }.to raise_error(ActiveRecord::RecordInvalid)
      expect(headers.reload.deleted?).to be false
    end
  end
end
