require "rails_helper"

RSpec.describe "Portfolio", type: :request do
  fixtures :projects

  let(:portfolio_site) { projects(:portfolio_site) }
  let(:ecommerce) { projects(:ecommerce_platform) }
  let(:mobile_app) { projects(:mobile_app) }

  describe "GET /portfolio" do
    it "returns success" do
      get portfolio_path
      expect(response).to have_http_status(:success)
    end

    it "lists all projects" do
      get portfolio_path
      expect(response.body).to include(portfolio_site.title)
      expect(response.body).to include(ecommerce.title)
      expect(response.body).to include(mobile_app.title)
    end

    it "shows client names" do
      get portfolio_path
      expect(response.body).to include(portfolio_site.client)
    end

    it "shows tech stack tags" do
      get portfolio_path
      expect(response.body).to include("Ruby")
      expect(response.body).to include("Rails")
    end

    it "shows featured badge for featured projects" do
      get portfolio_path
      # Featured projects get a "Featured" tag
      expect(response.body).to include("Featured")
    end

    it "links to individual projects" do
      get portfolio_path
      expect(response.body).to include(portfolio_project_path(portfolio_site))
    end
  end

  describe "GET /portfolio/:id" do
    it "returns success" do
      get portfolio_project_path(portfolio_site)
      expect(response).to have_http_status(:success)
    end

    it "shows project details" do
      get portfolio_project_path(portfolio_site)
      expect(response.body).to include(portfolio_site.title)
      expect(response.body).to include(portfolio_site.client)
      expect(response.body).to include(portfolio_site.description)
    end

    it "shows tech stack" do
      get portfolio_project_path(portfolio_site)
      portfolio_site.tech_stack.each do |tech|
        expect(response.body).to include(tech)
      end
    end

    it "shows highlights" do
      get portfolio_project_path(portfolio_site)
      portfolio_site.highlights.each do |highlight|
        expect(response.body).to include(highlight)
      end
    end

    it "shows featured badge when featured" do
      get portfolio_project_path(portfolio_site)
      expect(response.body).to include("Featured")
    end

    it "links back to portfolio index" do
      get portfolio_project_path(portfolio_site)
      expect(response.body).to include('href="/portfolio"')
    end

    context "with non-existent project" do
      it "returns 404" do
        get portfolio_project_path(id: 999999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
