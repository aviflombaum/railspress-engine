# frozen_string_literal: true

class CreateRailspressContentElements < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_content_elements do |t|
      t.string :name, null: false
      t.integer :content_type, default: 0, null: false
      t.text :text_content
      t.references :content_group, null: false, foreign_key: { to_table: :railspress_content_groups }
      t.bigint :author_id
      t.integer :position
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :railspress_content_elements, :deleted_at
    add_index :railspress_content_elements, :author_id
    add_index :railspress_content_elements, :content_type
  end
end
