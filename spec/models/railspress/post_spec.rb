require "rails_helper"

RSpec.describe Railspress::Post, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  fixtures "railspress/posts", "railspress/categories", "railspress/tags", "railspress/taggings"

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

    it "preserves published_at when unpublishing (allows scheduling)" do
      post = railspress_posts(:hello_world)
      original_published_at = post.published_at
      post.update!(status: :draft)
      expect(post.published_at).to eq(original_published_at)
    end
  end

  describe "tag_list" do
    it "returns comma-separated tag names" do
      post = railspress_posts(:hello_world)
      expect(post.tag_list.split(", ")).to match_array([ "ruby", "rails" ])
    end

    it "accepts CSV and assigns tags" do
      post = Railspress::Post.new(title: "Tagged Post")
      post.tag_list = "ruby, rails, tutorial"
      post.save!
      expect(post.tags.pluck(:name)).to match_array([ "ruby", "rails", "tutorial" ])
    end
  end

  describe "associations" do
    it "belongs to category" do
      post = railspress_posts(:hello_world)
      expect(post.category).to eq(railspress_categories(:technology))
    end

    it "has many tags through taggings" do
      post = railspress_posts(:hello_world)
      expect(post.tags.count).to eq(2)
    end

    it "destroys taggings when destroyed" do
      post = railspress_posts(:hello_world)
      tagging_ids = post.taggings.pluck(:id)
      post.destroy
      expect(Railspress::Tagging.where(id: tagging_ids)).to be_empty
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

  describe ".rp_search" do
    it "finds posts by partial title" do
      results = Railspress::Post.rp_search("Hello")
      expect(results).to include(railspress_posts(:hello_world))
      expect(results).not_to include(railspress_posts(:draft_post))
    end

    it "matches titles case-insensitively" do
      expect(Railspress::Post.rp_search("hELLo")).to include(railspress_posts(:hello_world))
    end

    it "returns no posts when the title does not match" do
      expect(Railspress::Post.rp_search("not-a-real-title")).to be_empty
    end

    it "leaves the relation unfiltered when the query is blank" do
      expect(Railspress::Post.rp_search("")).to match_array(Railspress::Post.all)
    end
  end

  describe ".search" do
    it "delegates to the RailsPress search" do
      allow(Railspress.deprecator).to receive(:warn)

      expect(Railspress::Post.search("Hello")).to include(railspress_posts(:hello_world))
    end

    it "warns that the compatibility method is deprecated" do
      allow(Railspress.deprecator).to receive(:warn)

      Railspress::Post.search("Hello")

      expect(Railspress.deprecator).to have_received(:warn).with(/use rp_search instead/)
    end
  end

  describe ".find_preview!" do
    before do
      Railspress.configure(&:enable_post_previews)
    end

    it "resolves the signed post when the slug and token are valid" do
      post = railspress_posts(:draft_post)
      token = post.preview_token

      expect(described_class.find_preview!(slug: post.slug, token: token)).to eq(post)
    end

    it "raises not found when previews are disabled" do
      post = railspress_posts(:draft_post)
      token = post.preview_token
      Railspress.reset_configuration!

      expect {
        described_class.find_preview!(slug: post.slug, token: token)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises not found when the token has a different purpose" do
      post = railspress_posts(:draft_post)
      token = post.signed_id(purpose: :another_purpose, expires_in: 1.hour)

      expect {
        described_class.find_preview!(slug: post.slug, token: token)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises not found when the URL slug does not match the signed post" do
      post = railspress_posts(:draft_post)

      expect {
        described_class.find_preview!(slug: "another-post", token: post.preview_token)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises not found when the signed post has been deleted" do
      post = railspress_posts(:draft_post)
      token = post.preview_token
      post.destroy!

      expect {
        described_class.find_preview!(slug: post.slug, token: token)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises not found when the token has expired" do
      post = railspress_posts(:draft_post)
      token = post.preview_token(expires_in: 1.minute)

      travel 2.minutes do
        expect {
          described_class.find_preview!(slug: post.slug, token: token)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#preview_token" do
    it "uses the configured expiration" do
      Railspress.configure do |config|
        config.enable_post_previews
        config.post_preview_expires_in = 1.minute
      end
      post = railspress_posts(:draft_post)
      token = post.preview_token

      travel 2.minutes do
        expect {
          described_class.find_preview!(slug: post.slug, token: token)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#scheduled?" do
    it "returns true when published_at is in the future" do
      post = Railspress::Post.new(published_at: 1.day.from_now)
      expect(post.scheduled?).to be true
    end

    it "returns false when published_at is nil" do
      post = Railspress::Post.new(published_at: nil)
      expect(post.scheduled?).to be false
    end

    it "returns false when published_at is in the past" do
      post = Railspress::Post.new(published_at: 1.day.ago)
      expect(post.scheduled?).to be false
    end
  end

  describe "#live?" do
    it "returns true when published_at is in the past" do
      post = Railspress::Post.new(status: :published, published_at: 1.day.ago)
      expect(post).to be_live
    end

    it "returns true when published_at is now" do
      post = Railspress::Post.new(status: :published, published_at: Time.current)
      expect(post).to be_live
    end

    it "returns false when published_at is nil" do
      post = Railspress::Post.new(status: :published, published_at: nil)
      expect(post).not_to be_live
    end

    it "returns false when published_at is in the future" do
      post = Railspress::Post.new(status: :published, published_at: 1.day.from_now)
      expect(post).not_to be_live
    end

    it "returns false for a draft that retains a past published_at" do
      post = Railspress::Post.new(status: :draft, published_at: 1.day.ago)
      expect(post).not_to be_live
    end
  end

  describe "#display_status" do
    it "returns 'scheduled' for published posts with future published_at" do
      post = railspress_posts(:scheduled_post)
      expect(post.display_status).to eq("scheduled")
    end

    it "returns 'published' for published posts with past published_at" do
      post = railspress_posts(:hello_world)
      expect(post.display_status).to eq("published")
    end

    it "returns 'draft' for drafts regardless of published_at" do
      post = railspress_posts(:draft_post)
      post.published_at = 1.day.from_now
      expect(post.display_status).to eq("draft")
    end
  end

  describe ".published scope" do
    it "excludes posts with future published_at" do
      freeze_time do
        expect(Railspress::Post.published).to include(railspress_posts(:hello_world))
        expect(Railspress::Post.published).not_to include(railspress_posts(:scheduled_post))
      end
    end

    it "excludes draft posts" do
      expect(Railspress::Post.published).not_to include(railspress_posts(:draft_post))
    end
  end

  describe ".scheduled scope" do
    it "returns only published posts with future published_at" do
      freeze_time do
        expect(Railspress::Post.scheduled).to include(railspress_posts(:scheduled_post))
        expect(Railspress::Post.scheduled).not_to include(railspress_posts(:hello_world))
        expect(Railspress::Post.scheduled).not_to include(railspress_posts(:draft_post))
      end
    end
  end

  describe ".by_status scope" do
    it "handles 'scheduled' filter" do
      freeze_time do
        results = Railspress::Post.by_status("scheduled")
        expect(results).to include(railspress_posts(:scheduled_post))
        expect(results).not_to include(railspress_posts(:hello_world))
      end
    end

    it "handles 'published' filter and excludes scheduled" do
      freeze_time do
        results = Railspress::Post.by_status("published")
        expect(results).to include(railspress_posts(:hello_world))
        expect(results).not_to include(railspress_posts(:scheduled_post))
      end
    end

    it "handles 'draft' filter" do
      results = Railspress::Post.by_status("draft")
      expect(results).to include(railspress_posts(:draft_post))
      expect(results).not_to include(railspress_posts(:hello_world))
    end

    it "returns all posts when filter is blank" do
      results = Railspress::Post.by_status("")
      expect(results.count).to eq(Railspress::Post.count)
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
