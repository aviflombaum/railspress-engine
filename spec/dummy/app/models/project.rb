# frozen_string_literal: true

class Project < ApplicationRecord
  include Railspress::Entity

  has_rich_text :body
  has_many_attached :gallery

  # Declare which fields appear in the CMS admin
  railspress_fields :title, :client, :featured
  railspress_fields :description # , as: :text
  railspress_fields :body # , as: :rich_text
  railspress_fields :gallery, as: :attachments
  railspress_fields :tech_stack, as: :list
  railspress_fields :highlights, as: :lines

  # Custom sidebar label
  railspress_label "Client Projects"

  validates :title, presence: true
end
