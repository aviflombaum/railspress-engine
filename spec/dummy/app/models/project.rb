# frozen_string_literal: true

class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::HasFocalPoint

  # Columns to display in the admin index table
  RAILSPRESS_INDEX_COLUMNS = [:title, :client, :featured, :created_at].freeze

  has_rich_text :body
  has_many_attached :gallery

  # Unified focal point image with variant configuration
  focal_point_image :main_image do |attachable|
    # Project hero: 21:9 ultra-wide
    attachable.variant :hero, resize_to_fill: [2100, 900, { crop: :centre }]
    attachable.variant :hero_md, resize_to_fill: [1680, 720, { crop: :centre }]
    # Project cards: 16:10 (landscape)
    attachable.variant :card, resize_to_fill: [800, 500, { crop: :centre }]
    attachable.variant :card_lg, resize_to_fill: [1600, 1000, { crop: :centre }]
    # Thumbnail
    attachable.variant :thumb, resize_to_fill: [400, 250, { crop: :centre }]
    # OG/Social sharing: 1.91:1 (Facebook/Twitter standard)
    attachable.variant :og, resize_to_fill: [1200, 630, { crop: :centre }]
  end

  # Declare which fields appear in the CMS admin
  railspress_fields :title, :client, :featured
  # main_image auto-registered by focal_point_image above
  railspress_fields :description # , as: :text
  railspress_fields :body # , as: :rich_text
  railspress_fields :gallery, as: :attachments
  railspress_fields :tech_stack, as: :list
  railspress_fields :highlights, as: :lines

  # Custom sidebar label
  railspress_label "Client Projects"

  validates :title, presence: true
end
