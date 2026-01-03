require "rails_helper"

RSpec.describe Railspress::Tagging, type: :model do
  fixtures "railspress/tags", "railspress/posts", "railspress/taggings"

  describe "associations" do
    it "belongs to tag" do
      tagging = railspress_taggings(:hello_world_ruby)
      expect(tagging.tag).to eq(railspress_tags(:ruby))
    end

    it "belongs to taggable (polymorphic)" do
      tagging = railspress_taggings(:hello_world_ruby)
      expect(tagging.taggable).to eq(railspress_posts(:hello_world))
      expect(tagging.taggable_type).to eq("Railspress::Post")
    end
  end

  describe "validations" do
    it "requires unique tag per taggable" do
      existing = railspress_taggings(:hello_world_ruby)
      duplicate = Railspress::Tagging.new(
        tag: existing.tag,
        taggable: existing.taggable
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tag_id]).to include("has already been applied to this item")
    end

    it "allows same tag on different taggables" do
      tag = railspress_tags(:ruby)
      post = railspress_posts(:draft_post)
      tagging = Railspress::Tagging.new(tag: tag, taggable: post)
      expect(tagging).to be_valid
    end
  end
end
