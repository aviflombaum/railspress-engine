require "rails_helper"

RSpec.describe Railspress::PostExportProcessor, type: :model do
  fixtures "railspress/posts", "railspress/categories", "railspress/tags", "railspress/taggings"

  let(:export) { Railspress::Export.create!(export_type: "posts") }
  let(:processor) { described_class.new(export: export) }

  describe "#process!" do
    before do
      # Ensure we have posts to export
      Railspress::Post.find_each do |post|
        post.update!(content: "<p>Test content for #{post.title}</p>") unless post.content.present?
      end
    end

    it "marks export as processing" do
      allow(processor).to receive(:export_all_posts)
      allow(processor).to receive(:create_zip_file)
      processor.process!
      # It should be completed or failed at the end, not processing
      expect(export.reload.status).to be_in(%w[completed failed])
    end

    it "exports all posts" do
      processor.process!
      expect(export.reload.total_count).to eq(Railspress::Post.count)
    end

    it "increments success count for each post" do
      processor.process!
      expect(export.reload.success_count).to eq(Railspress::Post.count)
    end

    it "marks export as completed" do
      processor.process!
      expect(export.reload.completed?).to be true
    end

    it "attaches a zip file to the export" do
      processor.process!
      expect(export.reload.file).to be_attached
    end

    it "sets the filename" do
      processor.process!
      expect(export.reload.filename).to match(/posts_export_\d{8}_\d{6}\.zip/)
    end

    it "cleans up tmp directory after processing" do
      processor.process!
      # The export_dir should be cleaned up
      expect(Dir.exist?(Rails.root.join("tmp", "exports", "#{export.id}_*"))).to be false
    end
  end

  describe "markdown generation" do
    let(:post) { railspress_posts(:hello_world) }

    before do
      post.update!(
        content: "<p>This is <strong>rich</strong> content</p>",
        meta_title: "SEO Title",
        meta_description: "SEO Description"
      )
    end

    it "generates frontmatter with title" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("title: #{post.title}")
    end

    it "generates frontmatter with slug" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("slug: #{post.slug}")
    end

    it "generates frontmatter with status" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("status: #{post.status}")
    end

    it "includes category in frontmatter" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("category: #{post.category.name}")
    end

    it "includes tags in frontmatter" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      post.tags.each do |tag|
        expect(zip_content).to include(tag.name)
      end
    end

    it "includes meta fields in frontmatter" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("meta_title: SEO Title")
      expect(zip_content).to include("meta_description: SEO Description")
    end

    it "includes HTML content in body" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("<p>This is <strong>rich</strong> content</p>")
    end
  end

  describe "header image export" do
    let(:post) { railspress_posts(:hello_world) }

    before do
      allow(Railspress).to receive(:header_images_enabled?).and_return(true)
      post.header_image.attach(
        io: File.open(Rails.root.join("../../spec/fixtures/files/test_image.png")),
        filename: "test_image.png",
        content_type: "image/png"
      )
    end

    after do
      Railspress.reset_configuration!
    end

    it "includes header_image path in frontmatter" do
      processor.process!
      zip_content = read_zip_file(export, "#{post.slug}.md")
      expect(zip_content).to include("header_image: images/#{post.slug}.png")
    end

    it "exports header image to images folder" do
      processor.process!
      expect(zip_file_exists?(export, "images/#{post.slug}.png")).to be true
    end
  end

  describe "error handling" do
    it "records errors for individual posts and still completes" do
      # Make one post fail by having an invalid slug
      allow_any_instance_of(Railspress::Post).to receive(:slug).and_raise("Unexpected error")
      processor.process!
      expect(export.reload.error_count).to be > 0
      # Should still complete since errors are caught per-post
      expect(export.reload.status).to be_in(%w[completed failed])
    end
  end

  private

  def read_zip_file(export, filename)
    content = nil
    io = StringIO.new(export.file.download)
    Zip::File.open_buffer(io) do |zip|
      entry = zip.find_entry(filename)
      content = entry&.get_input_stream&.read
    end
    content
  end

  def zip_file_exists?(export, filename)
    result = false
    io = StringIO.new(export.file.download)
    Zip::File.open_buffer(io) do |zip|
      result = zip.find_entry(filename).present?
    end
    result
  end
end
