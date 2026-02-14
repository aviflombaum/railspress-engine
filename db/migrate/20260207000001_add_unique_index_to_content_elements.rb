# frozen_string_literal: true

class AddUniqueIndexToContentElements < ActiveRecord::Migration[8.1]
  def change
    add_index :railspress_content_elements,
              [ :content_group_id, :name ],
              unique: true,
              where: "deleted_at IS NULL",
              name: "idx_content_elements_unique_name_per_group"
  end
end
