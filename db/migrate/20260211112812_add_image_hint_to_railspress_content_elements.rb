# frozen_string_literal: true

class AddImageHintToRailspressContentElements < ActiveRecord::Migration[8.1]
  def change
    add_column :railspress_content_elements, :image_hint, :string
  end
end
