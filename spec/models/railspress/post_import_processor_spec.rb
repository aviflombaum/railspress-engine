require "rails_helper"

RSpec.describe Railspress::PostImportProcessor, type: :model do
  fixtures "railspress/imports", "railspress/categories", "railspress/tags"

  let(:import) { railspress_imports(:pending_import) }
  let(:fixtures_path) { Rails.root.join("../../spec/fixtures/files") }

  describe "#process!" do
    context "with a valid markdown file" do
      let(:file_path) { fixtures_path.join("valid_post.md") }
      let(:processor) { described_class.new(import: import, file_path: file_path) }

      it "creates a post" do
        expect { processor.process! }.to change(Railspress::Post, :count).by(1)
      end

      it "marks import as completed" do
        processor.process!
        expect(import.reload.status).to eq("completed")
      end

      it "sets post attributes from frontmatter" do
        processor.process!
        post = Railspress::Post.find_by(slug: "my-imported-post")

        expect(post.title).to eq("My Imported Post")
        expect(post.slug).to eq("my-imported-post")
        expect(post.status).to eq("published")
        expect(post.published_at.to_date).to eq(Date.new(2024, 6, 15))
        expect(post.meta_title).to eq("SEO Title for Imported Post")
        expect(post.meta_description).to eq("This is the SEO description for the imported post.")
      end

      it "assigns category by case-insensitive name" do
        processor.process!
        post = Railspress::Post.find_by(slug: "my-imported-post")

        expect(post.category).to eq(railspress_categories(:technology))
      end

      it "assigns tags" do
        processor.process!
        post = Railspress::Post.find_by(slug: "my-imported-post")

        expect(post.tags.pluck(:name)).to include("ruby", "rails", "import")
      end

      it "sets rich text content" do
        processor.process!
        post = Railspress::Post.find_by(slug: "my-imported-post")

        expect(post.content.to_plain_text).to include("Welcome to My Blog")
        expect(post.content.to_plain_text).to include("body content")
      end

      it "increments success count" do
        processor.process!
        expect(import.reload.success_count).to eq(1)
      end

      it "increments total count" do
        processor.process!
        expect(import.reload.total_count).to eq(1)
      end
    end

    context "with a minimal markdown file" do
      let(:file_path) { fixtures_path.join("minimal_post.md") }
      let(:processor) { described_class.new(import: import, file_path: file_path) }

      it "creates a post with defaults" do
        expect { processor.process! }.to change(Railspress::Post, :count).by(1)
      end

      it "defaults to draft status" do
        processor.process!
        post = Railspress::Post.find_by(title: "Minimal Post")

        expect(post.status).to eq("draft")
      end

      it "defaults published_at to today" do
        processor.process!
        post = Railspress::Post.find_by(title: "Minimal Post")

        expect(post.published_at.to_date).to eq(Date.current)
      end
    end

    context "with markdown without frontmatter" do
      let(:file_path) { fixtures_path.join("no_frontmatter.md") }
      let(:processor) { described_class.new(import: import, file_path: file_path) }

      it "extracts title from first H1 heading" do
        processor.process!
        post = Railspress::Post.last

        expect(post.title).to eq("Title From Heading")
      end
    end

    context "with a plain text file" do
      let(:file_path) { fixtures_path.join("plain-text-post.txt") }
      let(:processor) { described_class.new(import: import, file_path: file_path) }

      it "creates a post" do
        expect { processor.process! }.to change(Railspress::Post, :count).by(1)
      end

      it "derives title from filename" do
        processor.process!
        post = Railspress::Post.last

        expect(post.title).to eq("Plain Text Post")
      end

      it "uses file content as body" do
        processor.process!
        post = Railspress::Post.last

        expect(post.content.to_plain_text).to include("plain text post")
      end
    end

    context "with invalid frontmatter" do
      let(:file_path) { fixtures_path.join("invalid_frontmatter.md") }
      let(:processor) { described_class.new(import: import, file_path: file_path) }

      it "does not create a post" do
        expect { processor.process! }.not_to change(Railspress::Post, :count)
      end

      it "records the error" do
        processor.process!
        expect(import.reload.error_count).to eq(1)
        expect(import.parsed_errors.first).to include("Invalid YAML frontmatter")
      end

      it "marks import as failed when no successes" do
        processor.process!
        expect(import.reload.status).to eq("failed")
      end
    end

    context "with unsupported file type" do
      let(:file_path) { fixtures_path.join("test_image.png") }
      let(:processor) { described_class.new(import: import, file_path: file_path) }

      it "records an error" do
        processor.process!
        expect(import.reload.error_count).to eq(1)
        expect(import.parsed_errors.first).to include("Unsupported file type")
      end
    end
  end

  describe "category matching" do
    let(:file_path) { fixtures_path.join("valid_post.md") }
    let(:processor) { described_class.new(import: import, file_path: file_path) }

    it "matches category case-insensitively" do
      # The fixture has "Technology" but let's verify it matches our "technology" fixture
      processor.process!
      post = Railspress::Post.last
      expect(post.category&.name).to eq("Technology")
    end

    it "ignores category if not found" do
      # Create a post with non-existent category by using a different fixture
      allow(File).to receive(:read).and_return(<<~MD)
        ---
        title: Test Post
        category: NonExistentCategory
        ---
        Content here.
      MD

      processor.process!
      post = Railspress::Post.last
      expect(post.category).to be_nil
    end
  end

  describe "tags handling" do
    let(:processor) { described_class.new(import: import, file_path: fixtures_path.join("valid_post.md")) }

    it "creates new tags that don't exist" do
      # The fixture has tags: ruby, rails, import
      # ruby and rails exist in fixtures, import does not
      expect { processor.process! }.to change(Railspress::Tag, :count).by(1)
      expect(Railspress::Tag.find_by(name: "import")).to be_present
    end

    it "reuses existing tags" do
      existing_tag = railspress_tags(:ruby)
      processor.process!
      post = Railspress::Post.last

      expect(post.tags).to include(existing_tag)
    end
  end

  describe "zip processing" do
    let(:file_path) { fixtures_path.join("posts_import.zip") }
    let(:processor) { described_class.new(import: import, file_path: file_path) }

    it "extracts and processes all markdown files from zip" do
      # Zip contains: post-with-image.md, simple-post.md, drafts/draft-post.md, plain-file.txt
      expect { processor.process! }.to change(Railspress::Post, :count).by(4)
    end

    it "processes files in subdirectories" do
      processor.process!
      draft_post = Railspress::Post.find_by(title: "Draft From Subdirectory")

      expect(draft_post).to be_present
      expect(draft_post.status).to eq("draft")
    end

    it "processes text files from zip" do
      processor.process!
      text_post = Railspress::Post.find_by(title: "Plain File")

      expect(text_post).to be_present
    end

    it "marks import as completed" do
      processor.process!
      expect(import.reload.status).to eq("completed")
    end

    it "tracks correct counts" do
      processor.process!
      expect(import.reload.total_count).to eq(4)
      expect(import.reload.success_count).to eq(4)
    end

    it "cleans up tmp directory after processing" do
      processor.process!
      # The extract_dir should be cleaned up
      expect(processor.extract_dir).to be_present
      expect(Dir.exist?(processor.extract_dir)).to be false
    end

    it "attaches header image from zip" do
      # Enable header images for this test
      allow(Railspress).to receive(:post_images_enabled?).and_return(true)

      processor.process!
      post_with_image = Railspress::Post.find_by(title: "Post With Header Image")

      expect(post_with_image.header_image).to be_attached
    end
  end

  describe "header image handling" do
    context "when header_images are disabled" do
      let(:processor) { described_class.new(import: import, file_path: fixtures_path.join("valid_post.md")) }

      before do
        allow(Railspress).to receive(:post_images_enabled?).and_return(false)
      end

      it "does not attempt to attach header image" do
        processor.process!
        post = Railspress::Post.last
        expect(post.header_image).not_to be_attached
      end
    end

    context "with URL header image" do
      let(:processor) { described_class.new(import: import, file_path: fixtures_path.join("valid_post.md")) }

      before do
        allow(Railspress).to receive(:post_images_enabled?).and_return(true)
      end

      it "detects URLs correctly" do
        expect(processor.send(:url?, "https://example.com/image.jpg")).to be true
        expect(processor.send(:url?, "http://example.com/image.png")).to be true
        expect(processor.send(:url?, "images/local.jpg")).to be false
        expect(processor.send(:url?, "../relative/path.png")).to be false
      end
    end
  end

  describe "invalid zip handling" do
    let(:processor) { described_class.new(import: import, file_path: fixtures_path.join("test_image.png")) }

    it "handles non-zip files gracefully" do
      processor.process!
      expect(import.reload.error_count).to eq(1)
      expect(import.parsed_errors.first).to include("Unsupported file type")
    end
  end
end
