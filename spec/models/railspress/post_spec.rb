require "rails_helper"

RSpec.describe Railspress::Post, type: :model do
  fixtures "railspress/posts", "railspress/categories", "railspress/tags", "railspress/post_tags"

  describe "validations" do
    it "requires a title" do
      post = Railspress::Post.new(title: nil)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "requires a unique slug" do
      post = Railspress::Post.new(title: "New Post", slug: "hello-world")
      expect(post).not_to be_valid
      expect(post.errors[:slug]).to include("has already been taken")
    end
  end

  describe "slug generation" do
    it "auto-generates a slug from the title" do
      post = Railspress::Post.new(title: "My New Post")
      post.valid?
      expect(post.slug).to eq("my-new-post")
    end

    it "generates unique slug with counter suffix" do
      post = Railspress::Post.new(title: "Hello World")
      post.valid?
      expect(post.slug).to eq("hello-world-1")
    end
  end

  describe "status" do
    it "defaults to draft" do
      post = Railspress::Post.new
      expect(post.draft?).to be true
    end

    it "sets published_at when publishing" do
      post = railspress_posts(:draft_post)
      post.update!(status: :published)
      expect(post.published_at).not_to be_nil
    end

    it "clears published_at when unpublishing" do
      post = railspress_posts(:hello_world)
      post.update!(status: :draft)
      expect(post.published_at).to be_nil
    end
  end

  describe "tag_list" do
    it "returns comma-separated tag names" do
      post = railspress_posts(:hello_world)
      expect(post.tag_list).to eq("rails, ruby")
    end

    it "accepts CSV and assigns tags" do
      post = Railspress::Post.new(title: "Tagged Post")
      post.tag_list = "ruby, rails, tutorial"
      post.save!
      expect(post.tags.pluck(:name)).to match_array(["ruby", "rails", "tutorial"])
    end
  end

  describe "associations" do
    it "belongs to category" do
      post = railspress_posts(:hello_world)
      expect(post.category).to eq(railspress_categories(:technology))
    end

    it "has many tags through post_tags" do
      post = railspress_posts(:hello_world)
      expect(post.tags.count).to eq(2)
    end
  end

  describe "scopes" do
    it "orders by created_at desc" do
      posts = Railspress::Post.ordered
      expect(posts.first.created_at).to be >= posts.last.created_at
    end

    it "limits to 10 recent posts" do
      posts = Railspress::Post.recent
      expect(posts.limit_value).to eq(10)
    end
  end

  describe "header_image" do
    let(:post) { Railspress::Post.create!(title: "Image Test") }
    let(:image_path) { Rails.root.join("../../spec/fixtures/files/test_image.png") }

    it "can attach a header image" do
      post.header_image.attach(
        io: File.open(image_path),
        filename: "test.png",
        content_type: "image/png"
      )
      expect(post.header_image).to be_attached
    end

    it "can remove header image via remove_header_image attribute" do
      post.header_image.attach(
        io: File.open(image_path),
        filename: "test.png",
        content_type: "image/png"
      )
      expect(post.header_image).to be_attached

      post.remove_header_image = "1"
      post.save!
      expect(post.reload.header_image).not_to be_attached
    end
  end
end
