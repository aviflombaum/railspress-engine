# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::CmsHelper, type: :helper do
  fixtures "railspress/content_groups", "railspress/content_elements"

  before do
    Railspress::CmsHelper.clear_cache
    allow(helper).to receive(:inline_editor_enabled?).and_return(false)
  end

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

  describe "#cms_element with image elements" do
    let(:image_element) do
      el = Railspress::ContentElement.create!(
        name: "Hero Image",
        content_type: :image,
        content_group: railspress_content_groups(:headers)
      )
      el.image.attach(
        io: StringIO.new("fake image data"),
        filename: "hero.png",
        content_type: "image/png"
      )
      el
    end

    it "returns nil for image with no attachment" do
      el = Railspress::ContentElement.create!(
        name: "No Image",
        content_type: :image,
        content_group: railspress_content_groups(:headers)
      )
      result = helper.cms_element(group: "Headers", name: "No Image")
      expect(result).to be_nil
    end

    it "renders img tag for image elements with attachment" do
      image_element # ensure element is created
      result = helper.cms_element(group: "Headers", name: "Hero Image")
      expect(result).to include("<img")
      expect(result).to include("Hero Image") # alt text
    end

    it "includes focal point CSS when focal point is set" do
      # Set a non-center focal point
      fp = image_element.image_focal_point
      fp.update!(focal_x: 0.25, focal_y: 0.75)

      result = helper.cms_element(group: "Headers", name: "Hero Image")
      expect(result).to include("object-position")
    end

    it "does not include object-position when focal point is centered" do
      # Default focal point is 0.5, 0.5 (center) — ensure element is created
      image_element
      result = helper.cms_element(group: "Headers", name: "Hero Image")
      # has_focal_point? returns false when at center, so no object-position added
      expect(result).not_to include("object-position")
    end
  end

  describe "#cms_element with inline editing" do
    before do
      allow(helper).to receive(:inline_editor_enabled?).and_return(true)
      # Stub engine route helpers for the helper spec context
      routes = double("routes")
      allow(routes).to receive(:inline_admin_content_element_path).and_return("/railspress/admin/content_elements/1/inline")
      allow(routes).to receive(:admin_content_element_path).and_return("/railspress/admin/content_elements/1")
      allow(routes).to receive(:edit_admin_content_element_path).and_return("/railspress/admin/content_elements/1/edit")
      allow(helper).to receive(:railspress).and_return(routes)
    end

    it "wraps content in a span with Stimulus controller" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to include('data-controller="rp--cms-inline-editor"')
      expect(result).to include("<span")
    end

    it "includes display:contents style on wrapper" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to include("display:contents")
    end

    it "includes Stimulus data values" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to include("data-rp--cms-inline-editor-inline-path-value")
      expect(result).to include("data-rp--cms-inline-editor-frame-id-value")
      expect(result).to include("data-rp--cms-inline-editor-form-frame-id-value")
      expect(result).to include("data-rp--cms-inline-editor-element-id-value")
    end

    it "includes contextmenu action" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to include("contextmenu-&gt;rp--cms-inline-editor#open")
    end

    it "includes a display turbo-frame" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to include("<turbo-frame")
      expect(result).to include("Welcome to Our Site")
    end

    it "includes hidden menu and backdrop" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to include("rp-inline-menu")
      expect(result).to include("rp-inline-backdrop")
      expect(result).to include("rp-inline-hidden")
    end

    it "generates unique frame IDs for duplicate elements" do
      result1 = helper.cms_element(group: "Headers", name: "Homepage H1")
      result2 = helper.cms_element(group: "Headers", name: "Homepage H1")

      frame_ids1 = result1.scan(/id="cms_display_\d+_([a-f0-9]+)"/).flatten
      frame_ids2 = result2.scan(/id="cms_display_\d+_([a-f0-9]+)"/).flatten

      expect(frame_ids1.first).not_to eq(frame_ids2.first)
    end

    it "does not wrap when inline editing is disabled" do
      allow(helper).to receive(:inline_editor_enabled?).and_return(false)
      result = helper.cms_element(group: "Headers", name: "Homepage H1")
      expect(result).to eq("Welcome to Our Site")
      expect(result).not_to include("data-controller")
    end

    it "does not wrap non-existent elements" do
      result = helper.cms_element(group: "Headers", name: "NonExistent")
      expect(result).to be_nil
    end

    it "wraps block content" do
      result = helper.cms_element(group: "Headers", name: "Homepage H1") { |v| "<h1>#{v}</h1>".html_safe }
      expect(result).to include('data-controller="rp--cms-inline-editor"')
      expect(result).to include("<h1>Welcome to Our Site</h1>")
    end
  end

  describe "#inline_editor_enabled?" do
    before do
      allow(helper).to receive(:inline_editor_enabled?).and_call_original
    end

    it "returns false when no check is configured" do
      allow(Railspress).to receive(:inline_editing_check).and_return(nil)
      expect(helper.inline_editor_enabled?).to be false
    end

    it "returns true when check returns true" do
      allow(Railspress).to receive(:inline_editing_check).and_return(->(_) { true })
      expect(helper.inline_editor_enabled?).to be true
    end

    it "returns false when check returns false" do
      allow(Railspress).to receive(:inline_editing_check).and_return(->(_) { false })
      expect(helper.inline_editor_enabled?).to be false
    end

    it "returns false when check raises an error" do
      allow(Railspress).to receive(:inline_editing_check).and_return(->(_) { raise "boom" })
      expect(helper.inline_editor_enabled?).to be false
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
