require "rails_helper"

RSpec.describe Railspress::Tag, type: :model do
  fixtures "railspress/tags", "railspress/posts", "railspress/taggings"

  describe "validations" do
    it "requires a name" do
      tag = Railspress::Tag.new(name: nil)
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name (case-insensitive)" do
      tag = Railspress::Tag.new(name: "Ruby")
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("has already been taken")
    end

    it "normalizes name to lowercase" do
      tag = Railspress::Tag.new(name: "JAVASCRIPT")
      tag.valid?
      expect(tag.name).to eq("javascript")
    end
  end

  describe ".from_csv" do
    it "creates tags from CSV string" do
      tags = Railspress::Tag.from_csv("python, django, api")
      expect(tags.map(&:name)).to eq(["python", "django", "api"])
    end

    it "returns existing tags when they exist" do
      tags = Railspress::Tag.from_csv("ruby, rails")
      expect(tags.map(&:id)).to eq([
        railspress_tags(:ruby).id,
        railspress_tags(:rails).id
      ])
    end

    it "handles mixed case and whitespace" do
      tags = Railspress::Tag.from_csv("  Python ,  Django  ")
      expect(tags.map(&:name)).to eq(["python", "django"])
    end

    it "ignores empty strings and duplicates" do
      tags = Railspress::Tag.from_csv("python, , python, django")
      expect(tags.map(&:name)).to eq(["python", "django"])
    end

    it "returns empty array for blank input" do
      expect(Railspress::Tag.from_csv("")).to eq([])
      expect(Railspress::Tag.from_csv(nil)).to eq([])
    end
  end

  describe "associations" do
    it "has many taggings" do
      tag = railspress_tags(:ruby)
      expect(tag.taggings.count).to eq(1)
    end

    it "has many posts through taggings" do
      tag = railspress_tags(:ruby)
      expect(tag.posts).to include(railspress_posts(:hello_world))
    end

    it "destroys taggings when destroyed" do
      tag = railspress_tags(:tutorial)
      tag.destroy
      expect(Railspress::Tagging.where(tag_id: tag.id)).to be_empty
    end
  end
end
