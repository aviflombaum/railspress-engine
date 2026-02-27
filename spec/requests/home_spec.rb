require "rails_helper"

RSpec.describe "Home Page", type: :request do
  fixtures "railspress/categories", "railspress/posts",
           "railspress/content_groups", "railspress/content_elements",
           :projects

  let(:published_post) { railspress_posts(:hello_world) }
  let(:featured_project) { projects(:portfolio_site) }

  describe "GET /" do
    it "returns success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "renders CMS block content" do
      get root_path
      expect(response.body).to include("Build with RailsPress")
      expect(response.body).to include("A complete CMS for Rails 8")
      expect(response.body).to include("View Our Work")
    end

    it "shows recent published posts" do
      get root_path
      expect(response.body).to include(published_post.title)
    end

    it "shows featured projects" do
      get root_path
      expect(response.body).to include(featured_project.title)
      expect(response.body).to include(featured_project.client)
    end

    it "does not show non-featured projects" do
      get root_path
      non_featured = projects(:mobile_app)
      expect(response.body).not_to include(non_featured.title)
    end

    it "includes navigation links" do
      get root_path
      expect(response.body).to include('href="/blog"')
      expect(response.body).to include('href="/portfolio"')
    end
  end
end
