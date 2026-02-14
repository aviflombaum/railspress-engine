# frozen_string_literal: true

class CreateRailspressContentElementVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_content_element_versions do |t|
      t.references :content_element, null: false, foreign_key: { to_table: :railspress_content_elements }
      t.bigint :author_id
      t.text :text_content
      t.integer :version_number, null: false

      t.timestamps
    end

    add_index :railspress_content_element_versions,
              [ :content_element_id, :version_number ],
              unique: true,
              name: "idx_content_element_versions_unique"
    add_index :railspress_content_element_versions, :author_id
  end
end
