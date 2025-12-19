require "rails_helper"

RSpec.describe Railspress::PostTag, type: :model do
  fixtures "railspress/posts", "railspress/tags", "railspress/post_tags"

  describe "validations" do
    it "prevents duplicate post-tag combinations" do
      post = railspress_posts(:hello_world)
      tag = railspress_tags(:ruby)
      post_tag = Railspress::PostTag.new(post: post, tag: tag)
      expect(post_tag).not_to be_valid
      expect(post_tag.errors[:post_id]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "belongs to post" do
      post_tag = railspress_post_tags(:hello_world_ruby)
      expect(post_tag.post).to eq(railspress_posts(:hello_world))
    end

    it "belongs to tag" do
      post_tag = railspress_post_tags(:hello_world_ruby)
      expect(post_tag.tag).to eq(railspress_tags(:ruby))
    end
  end
end
