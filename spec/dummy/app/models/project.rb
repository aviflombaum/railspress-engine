# frozen_string_literal: true

class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::HasFocalPoint

  # Columns to display in the admin index table
  RAILSPRESS_INDEX_COLUMNS = [:title, :client, :featured, :created_at].freeze

  has_rich_text :body
  has_one_attached :main_image
  has_many_attached :gallery

  # Enable focal point editing for the main image
  has_focal_point :main_image

  # Declare which fields appear in the CMS admin
  railspress_fields :title, :client, :featured
  railspress_fields :main_image, as: :focal_point_image
  railspress_fields :description # , as: :text
  railspress_fields :body # , as: :rich_text
  railspress_fields :gallery, as: :attachments
  railspress_fields :tech_stack, as: :list
  railspress_fields :highlights, as: :lines

  # Custom sidebar label
  railspress_label "Client Projects"

  validates :title, presence: true
end
