class CreateRailspressTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_taggings do |t|
      t.references :tag, null: false, foreign_key: { to_table: :railspress_tags }
      t.references :taggable, polymorphic: true, null: false
      t.timestamps
    end

    # Unique constraint: one tag per taggable
    add_index :railspress_taggings,
              [:tag_id, :taggable_type, :taggable_id],
              unique: true,
              name: "index_taggings_unique"

    # For "find all entities with tag X" queries
    add_index :railspress_taggings,
              [:taggable_type, :taggable_id],
              name: "index_taggings_on_taggable"
  end
end
