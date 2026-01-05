# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::HasFocalPoint do
  fixtures "railspress/posts", "railspress/categories", "railspress/focal_points"

  let(:post) { railspress_posts(:hello_world) }
  let(:post_with_focal) { railspress_posts(:post_with_focal_point) }

  describe "#focal_point" do
    it "returns default center when no focal point record exists" do
      expect(post.focal_point(:header_image)).to eq({ x: 0.5, y: 0.5 })
    end

    it "returns saved coordinates from focal point record" do
      expect(post_with_focal.focal_point(:header_image)).to eq({ x: 0.3, y: 0.7 })
    end

    it "uses default attachment when not specified" do
      expect(post.focal_point).to eq({ x: 0.5, y: 0.5 })
    end
  end

  describe "#focal_point_css" do
    it "returns object-position CSS" do
      post.header_image_focal_point.update!(focal_x: 0.35, focal_y: 0.7)
      expect(post.focal_point_css(:header_image)).to eq("object-position: 35.0% 70.0%")
    end

    it "rounds to one decimal place" do
      post.header_image_focal_point.update!(focal_x: 0.333, focal_y: 0.666)
      expect(post.focal_point_css(:header_image)).to eq("object-position: 33.3% 66.6%")
    end
  end

  describe "#has_focal_point?" do
    it "returns false for center" do
      expect(post.has_focal_point?(:header_image)).to be false
    end

    it "returns true when offset from center" do
      post.header_image_focal_point.update!(focal_x: 0.3, focal_y: 0.5)
      expect(post.has_focal_point?(:header_image)).to be true
    end

    it "returns true for preset focal point" do
      expect(post_with_focal.has_focal_point?(:header_image)).to be true
    end
  end

  describe "#image_override" do
    it "returns nil when no override" do
      expect(post.image_override(:hero, :header_image)).to be_nil
    end

    it "returns override data when set" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "crop", "region" => {} } })
      override = post.image_override(:hero, :header_image)
      expect(override[:type]).to eq("crop")
    end

    it "returns nil for unset context even when other contexts have overrides" do
      post.header_image_focal_point.update!(overrides: { "card" => { "type" => "crop" } })
      expect(post.image_override(:hero, :header_image)).to be_nil
    end
  end

  describe "#has_image_override?" do
    it "returns false when no override" do
      expect(post.has_image_override?(:hero, :header_image)).to be false
    end

    it "returns false for focal type override" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "focal" } })
      expect(post.has_image_override?(:hero, :header_image)).to be false
    end

    it "returns true for crop type override" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "crop" } })
      expect(post.has_image_override?(:hero, :header_image)).to be true
    end

    it "returns true for upload type override" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "upload" } })
      expect(post.has_image_override?(:hero, :header_image)).to be true
    end
  end

  describe "#set_image_override" do
    it "sets override for context" do
      post.set_image_override(:hero, { "type" => "crop", "region" => { "x" => 0.1 } }, :header_image)
      expect(post.header_image_focal_point.overrides["hero"]["type"]).to eq("crop")
    end

    it "preserves existing overrides" do
      post.header_image_focal_point.update!(overrides: { "card" => { "type" => "focal" } })
      post.set_image_override(:hero, { "type" => "crop" }, :header_image)
      expect(post.header_image_focal_point.overrides["card"]["type"]).to eq("focal")
      expect(post.header_image_focal_point.overrides["hero"]["type"]).to eq("crop")
    end
  end

  describe "#clear_image_override" do
    it "reverts context to focal type" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "crop" } })
      post.clear_image_override(:hero, :header_image)
      expect(post.header_image_focal_point.overrides["hero"]["type"]).to eq("focal")
    end
  end

  describe "#image_for" do
    it "returns original attachment when no override" do
      expect(post.image_for(:hero, :header_image)).to eq(post.header_image)
    end

    it "returns original attachment for crop override" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "crop", "region" => {} } })
      expect(post.image_for(:hero, :header_image)).to eq(post.header_image)
    end

    it "returns original attachment for focal override" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "focal" } })
      expect(post.image_for(:hero, :header_image)).to eq(post.header_image)
    end

    it "returns blob for upload override with valid signed_id" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test image data"),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
      post.header_image_focal_point.update!(overrides: {
        "hero" => { "type" => "upload", "blob_signed_id" => blob.signed_id }
      })
      expect(post.image_for(:hero, :header_image)).to eq(blob)
    end

    it "falls back to original for invalid blob signed_id" do
      post.header_image_focal_point.update!(overrides: {
        "hero" => { "type" => "upload", "blob_signed_id" => "invalid_signed_id" }
      })
      expect(post.image_for(:hero, :header_image)).to eq(post.header_image)
    end
  end

  describe "#image_css_for" do
    it "returns focal point CSS for no override" do
      post.header_image_focal_point.update!(focal_x: 0.3, focal_y: 0.7)
      expect(post.image_css_for(:hero, :header_image)).to eq("object-position: 30.0% 70.0%")
    end

    it "returns focal point CSS for focal type override" do
      post.header_image_focal_point.update!(
        focal_x: 0.3,
        focal_y: 0.7,
        overrides: { "hero" => { "type" => "focal" } }
      )
      expect(post.image_css_for(:hero, :header_image)).to eq("object-position: 30.0% 70.0%")
    end

    it "returns centered CSS for upload override" do
      post.header_image_focal_point.update!(overrides: { "hero" => { "type" => "upload", "blob_signed_id" => "x" } })
      expect(post.image_css_for(:hero, :header_image)).to eq("object-position: 50% 50%")
    end

    it "returns crop-based CSS for crop override" do
      post.header_image_focal_point.update!(overrides: {
        "hero" => {
          "type" => "crop",
          "region" => { "x" => 0.1, "y" => 0.2, "width" => 0.6, "height" => 0.5 }
        }
      })
      # x_offset = (0.1 + 0.3) * 100 = 40%, y_offset = (0.2 + 0.25) * 100 = 45%
      expect(post.image_css_for(:hero, :header_image)).to eq("object-position: 40.0% 45.0%")
    end

    it "falls back to focal point for crop without region" do
      post.header_image_focal_point.update!(
        focal_x: 0.25,
        focal_y: 0.75,
        overrides: { "hero" => { "type" => "crop" } }
      )
      expect(post.image_css_for(:hero, :header_image)).to eq("object-position: 25.0% 75.0%")
    end
  end

  describe "#reset_focal_point!" do
    it "resets focal point to center" do
      post_with_focal.reset_focal_point!(:header_image)
      expect(post_with_focal.header_image_focal_point.focal_x).to eq(0.5)
      expect(post_with_focal.header_image_focal_point.focal_y).to eq(0.5)
    end
  end

  describe "auto-building focal point association" do
    it "auto-builds focal point on first access" do
      new_post = Railspress::Post.new(title: "Test", slug: "test")
      fp = new_post.header_image_focal_point
      expect(fp).to be_a(Railspress::FocalPoint)
      expect(fp.focal_x).to eq(0.5)
      expect(fp.focal_y).to eq(0.5)
    end
  end

  describe ".focal_point_attachments" do
    it "returns registered attachment names" do
      expect(Railspress::Post.focal_point_attachments).to include(:header_image)
    end
  end
end

RSpec.describe Railspress::FocalPoint do
  fixtures "railspress/posts"

  describe "validations" do
    let(:post) { railspress_posts(:hello_world) }
    let(:focal_point) { Railspress::FocalPoint.new(record: post, attachment_name: "header_image") }

    it "rejects focal_x below 0" do
      focal_point.focal_x = -0.1
      expect(focal_point).not_to be_valid
      expect(focal_point.errors[:focal_x]).to be_present
    end

    it "rejects focal_x above 1" do
      focal_point.focal_x = 1.1
      expect(focal_point).not_to be_valid
      expect(focal_point.errors[:focal_x]).to be_present
    end

    it "rejects focal_y below 0" do
      focal_point.focal_y = -0.1
      expect(focal_point).not_to be_valid
      expect(focal_point.errors[:focal_y]).to be_present
    end

    it "rejects focal_y above 1" do
      focal_point.focal_y = 1.1
      expect(focal_point).not_to be_valid
      expect(focal_point.errors[:focal_y]).to be_present
    end

    it "accepts valid focal point values" do
      focal_point.focal_x = 0.0
      focal_point.focal_y = 1.0
      expect(focal_point).to be_valid
    end

    it "rejects invalid override type" do
      focal_point.overrides = { "hero" => { "type" => "invalid" } }
      expect(focal_point).not_to be_valid
      expect(focal_point.errors[:overrides]).to be_present
    end

    it "accepts valid override types" do
      focal_point.overrides = {
        "hero" => { "type" => "focal" },
        "card" => { "type" => "crop" },
        "thumb" => { "type" => "upload" }
      }
      expect(focal_point).to be_valid
    end

    it "allows empty overrides" do
      focal_point.overrides = {}
      expect(focal_point).to be_valid
    end

    it "allows nil override value for context" do
      focal_point.overrides = { "hero" => nil }
      expect(focal_point).to be_valid
    end
  end
end
