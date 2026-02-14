class DropRailspressPostTags < ActiveRecord::Migration[8.0]
  def up
    drop_table :railspress_post_tags
  end

  def down
    create_table :railspress_post_tags do |t|
      t.references :post, null: false, foreign_key: { to_table: :railspress_posts }
      t.references :tag, null: false, foreign_key: { to_table: :railspress_tags }
      t.timestamps
    end
    add_index :railspress_post_tags, [ :post_id, :tag_id ], unique: true
  end
end
