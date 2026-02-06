# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::CmsHelper, type: :helper do
  fixtures "railspress/content_groups", "railspress/content_elements"

  before { Railspress::CmsHelper.clear_cache }

  describe "#cms_value" do
    it "returns the value for a valid group and element" do
      value = helper.cms_value("Headers", "Homepage H1")
      expect(value).to eq("Welcome to Our Site")
    end

    it "returns nil for non-existent group" do
      value = helper.cms_value("NonExistent", "Homepage H1")
      expect(value).to be_nil
    end

    it "returns nil for non-existent element" do
      value = helper.cms_value("Headers", "NonExistent")
      expect(value).to be_nil
    end

    it "returns nil for deleted group elements" do
      value = helper.cms_value("Deleted Group", "Some Element")
      expect(value).to be_nil
    end
  end

  describe "#cms_element" do
    it "returns the value without a block" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to eq("Welcome to Our Site")
    end

    it "yields value and element to a block" do
      helper.cms_element(group: "Headers", name: "Homepage H1") do |value, element|
        expect(value).to eq("Welcome to Our Site")
        expect(element).to be_a(Railspress::ContentElement)
      end
    end

    it "returns nil for non-existent elements" do
      result = helper.cms_element(group: "Headers", name: "NonExistent")
      expect(result).to be_nil
    end
  end

  describe Railspress::CMS do
    it "finds a group and loads an element via chainable API" do
      value = Railspress::CMS.find("Headers").load("Homepage H1").value
      expect(value).to eq("Welcome to Our Site")
    end

    it "returns the element object" do
      element = Railspress::CMS.find("Headers").load("Homepage H1").element
      expect(element).to be_a(Railspress::ContentElement)
      expect(element.name).to eq("Homepage H1")
    end

    it "returns nil for missing groups" do
      value = Railspress::CMS.find("Missing").load("Element").value
      expect(value).to be_nil
    end

    it "returns nil for missing elements" do
      value = Railspress::CMS.find("Headers").load("Missing").value
      expect(value).to be_nil
    end

    it "caches results" do
      Railspress::CMS.find("Headers").load("Homepage H1").value
      expect(Railspress::CmsHelper.cache).not_to be_empty
    end
  end

  describe "cache management" do
    it "clears cache" do
      Railspress::CMS.find("Headers").load("Homepage H1").value
      expect(Railspress::CmsHelper.cache).not_to be_empty

      Railspress::CmsHelper.clear_cache
      expect(Railspress::CmsHelper.cache).to be_empty
    end
  end
end
