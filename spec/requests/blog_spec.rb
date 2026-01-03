require "rails_helper"

RSpec.describe "Blog Frontend", type: :request do
  # Use fixtures from the engine
  fixtures "railspress/categories", "railspress/tags", "railspress/posts", "railspress/taggings"

  let(:category) { railspress_categories(:technology) }
  let(:tag) { railspress_tags(:ruby) }
  let(:published_post) { railspress_posts(:hello_world) }
  let(:draft_post) { railspress_posts(:draft_post) }

  describe "GET /blog" do
    it "returns success" do
      get blog_path
      expect(response).to have_http_status(:success)
    end

    it "displays published posts" do
      get blog_path
      expect(response.body).to include("Hello World")
    end

    it "does not display draft posts" do
      get blog_path
      expect(response.body).not_to include("Draft Post")
    end

    it "includes post metadata" do
      get blog_path
      expect(response.body).to include("post-meta")
      expect(response.body).to include("post-excerpt")
    end

    it "links to individual posts" do
      get blog_path
      expect(response.body).to include('href="/blog/hello-world"')
    end

    it "links to categories" do
      get blog_path
      expect(response.body).to include('href="/blog/category/technology"')
    end

    it "links to tags" do
      get blog_path
      expect(response.body).to include('href="/blog/tag/ruby"')
    end

    it "includes search form" do
      get blog_path
      expect(response.body).to include('action="/blog/search"')
    end
  end

  describe "GET /blog/:slug" do
    context "with published post" do
      it "returns success" do
        get blog_post_path(slug: "hello-world")
        expect(response).to have_http_status(:success)
      end

      it "displays post title" do
        get blog_post_path(slug: "hello-world")
        expect(response.body).to include("Hello World")
      end

      it "displays post content" do
        get blog_post_path(slug: "hello-world")
        expect(response.body).to include("post-content")
      end

      it "displays category link" do
        get blog_post_path(slug: "hello-world")
        expect(response.body).to include("Technology")
        expect(response.body).to include('href="/blog/category/technology"')
      end

      it "displays tag links" do
        get blog_post_path(slug: "hello-world")
        expect(response.body).to include("ruby")
        expect(response.body).to include('href="/blog/tag/ruby"')
      end

      it "includes back to blog link" do
        get blog_post_path(slug: "hello-world")
        expect(response.body).to include('href="/blog"')
        expect(response.body).to include("Back to Blog")
      end
    end

    context "with draft post" do
      it "returns 404" do
        get blog_post_path(slug: "draft-post")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with non-existent slug" do
      it "returns 404" do
        get blog_post_path(slug: "non-existent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /blog/category/:slug" do
    it "returns success" do
      get blog_category_path(slug: "technology")
      expect(response).to have_http_status(:success)
    end

    it "displays category name" do
      get blog_category_path(slug: "technology")
      expect(response.body).to include("Category: Technology")
    end

    it "displays posts in category" do
      get blog_category_path(slug: "technology")
      expect(response.body).to include("Hello World")
    end

    it "does not display draft posts in category" do
      get blog_category_path(slug: "business")
      expect(response.body).not_to include("Draft Post")
    end

    it "shows post count" do
      get blog_category_path(slug: "technology")
      expect(response.body).to match(/\d+ posts?/)
    end

    context "with non-existent category" do
      it "returns 404" do
        get blog_category_path(slug: "non-existent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /blog/tag/:slug" do
    it "returns success" do
      get blog_tag_path(slug: "ruby")
      expect(response).to have_http_status(:success)
    end

    it "displays tag name" do
      get blog_tag_path(slug: "ruby")
      expect(response.body).to include("Tagged: ruby")
    end

    it "displays posts with tag" do
      get blog_tag_path(slug: "ruby")
      expect(response.body).to include("Hello World")
    end

    it "shows post count" do
      get blog_tag_path(slug: "ruby")
      expect(response.body).to match(/\d+ posts?/)
    end

    context "with non-existent tag" do
      it "returns 404" do
        get blog_tag_path(slug: "non-existent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /blog/search" do
    it "returns success" do
      get blog_search_path
      expect(response).to have_http_status(:success)
    end

    context "without query" do
      it "prompts user to search" do
        get blog_search_path
        expect(response.body).to include("Enter a search term")
      end
    end

    context "with matching query" do
      it "finds posts by title" do
        get blog_search_path, params: { q: "Hello" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Hello World")
      end

      it "shows result count" do
        get blog_search_path, params: { q: "Hello" }
        expect(response.body).to match(/Found \d+ results? for/)
      end

      it "does not find draft posts" do
        get blog_search_path, params: { q: "Draft" }
        expect(response.body).to include("No results found")
      end
    end

    context "with non-matching query" do
      it "shows no results message" do
        get blog_search_path, params: { q: "xyznonexistent" }
        expect(response.body).to include("No results found")
      end
    end
  end

  describe "published scope" do
    it "only returns published posts with published_at set" do
      published_posts = Railspress::Post.published
      expect(published_posts.pluck(:title)).to include("Hello World")
      expect(published_posts.pluck(:title)).not_to include("Draft Post")
    end

    it "excludes posts without published_at even if status is published" do
      # Create a post then clear published_at via update_column to bypass callback
      post = Railspress::Post.create!(title: "Broken Post", status: :draft)
      post.update_columns(status: 1, published_at: nil) # Set status to published but no date

      expect(Railspress::Post.published).not_to include(post)
    end
  end
end
