require "rails_helper"

RSpec.describe Railspress::Taggable, type: :model do
  fixtures "railspress/tags", "railspress/posts", "railspress/taggings", "railspress/categories"

  # Test using Post as the taggable model
  let(:post) { railspress_posts(:hello_world) }

  describe "associations" do
    it "has many taggings" do
      expect(post.taggings.count).to eq(2)
    end

    it "has many tags through taggings" do
      expect(post.tags).to include(railspress_tags(:ruby), railspress_tags(:rails))
    end

    it "destroys taggings when destroyed" do
      tagging_ids = post.taggings.pluck(:id)
      post.destroy
      expect(Railspress::Tagging.where(id: tagging_ids)).to be_empty
    end
  end

  describe "#tag_list" do
    it "returns comma-separated tag names" do
      expect(post.tag_list).to eq("ruby, rails")
    end

    it "returns empty string when no tags" do
      post_without_tags = railspress_posts(:draft_post)
      expect(post_without_tags.tag_list).to eq("")
    end
  end

  describe "#tag_list=" do
    it "creates and assigns tags from CSV" do
      new_post = Railspress::Post.new(
        title: "New Post",
        category: railspress_categories(:technology)
      )
      new_post.tag_list = "python, django, api"
      new_post.save!

      expect(new_post.tags.pluck(:name)).to eq(["python", "django", "api"])
    end

    it "finds existing tags instead of creating duplicates" do
      new_post = Railspress::Post.new(
        title: "Another Post",
        category: railspress_categories(:technology)
      )
      new_post.tag_list = "ruby, rails"
      new_post.save!

      expect(new_post.tags).to include(railspress_tags(:ruby), railspress_tags(:rails))
    end

    it "replaces existing tags" do
      post.tag_list = "javascript, react"
      post.save!

      expect(post.tags.pluck(:name)).to eq(["javascript", "react"])
      expect(post.tags).not_to include(railspress_tags(:ruby))
    end

    it "handles empty string" do
      post.tag_list = ""
      post.save!

      expect(post.tags).to be_empty
    end
  end
end
