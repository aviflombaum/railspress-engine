# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CMS feature gating" do
  describe "blog-only mode (CMS disabled)" do
    before { Railspress.reset_configuration! }

    describe "Railspress::CMS.find" do
      it "raises ConfigurationError" do
        expect {
          Railspress::CMS.find("Homepage")
        }.to raise_error(Railspress::ConfigurationError, /enable_cms/)
      end
    end

    describe "dashboard", type: :request do
      it "loads without CMS stats" do
        get railspress.admin_root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Content Groups")
        expect(response.body).not_to include("Content Elements")
      end

      it "does not show Recent Content section" do
        get railspress.admin_root_path
        expect(response.body).not_to include("Recent Content")
      end
    end

    describe "sidebar", type: :request do
      it "does not show CMS navigation links" do
        get railspress.admin_root_path
        expect(response.body).not_to include("Content Groups")
        expect(response.body).not_to include("Content Elements")
        expect(response.body).not_to include("CMS Transfer")
      end

      it "still shows blog navigation links" do
        get railspress.admin_root_path
        expect(response.body).to include("Posts")
        expect(response.body).to include("Categories")
        expect(response.body).to include("Tags")
      end
    end
  end

  describe "CMS enabled mode" do
    before do
      Railspress.reset_configuration!
      Railspress.configuration.enable_cms
    end

    describe "Railspress::CMS.find" do
      it "does not raise" do
        expect {
          Railspress::CMS.find("Nonexistent")
        }.not_to raise_error
      end
    end

    describe "dashboard", type: :request do
      it "shows CMS stats" do
        get railspress.admin_root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Content Groups")
        expect(response.body).to include("Content Elements")
      end
    end

    describe "sidebar", type: :request do
      it "shows CMS navigation links" do
        get railspress.admin_root_path
        expect(response.body).to include("Content Groups")
        expect(response.body).to include("Content Elements")
        expect(response.body).to include("CMS Transfer")
      end
    end
  end
end
