require "rails_helper"

RSpec.describe Railspress::Category, type: :model do
  fixtures "railspress/categories"

  describe "validations" do
    it "requires a name" do
      category = Railspress::Category.new(name: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name" do
      category = Railspress::Category.new(name: "Technology")
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("has already been taken")
    end
  end

  describe "slug generation" do
    it "auto-generates a slug from the name" do
      category = Railspress::Category.new(name: "New Category")
      category.valid?
      expect(category.slug).to eq("new-category")
    end

    it "does not overwrite an existing slug" do
      category = Railspress::Category.new(name: "New Category", slug: "custom-slug")
      category.valid?
      expect(category.slug).to eq("custom-slug")
    end
  end

  describe "scopes" do
    it "orders by name" do
      categories = Railspress::Category.ordered
      expect(categories.first.name).to eq("Business")
      expect(categories.last.name).to eq("Technology")
    end
  end
end
