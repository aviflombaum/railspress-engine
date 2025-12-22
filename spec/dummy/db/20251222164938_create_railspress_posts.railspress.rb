# This migration comes from railspress (originally 20241218000003)
class CreateRailspressPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.references :category, null: true, foreign_key: { to_table: :railspress_categories }
      t.bigint :author_id
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end

    add_index :railspress_posts, :slug, unique: true
    add_index :railspress_posts, :status
    add_index :railspress_posts, :published_at
    add_index :railspress_posts, :author_id
  end
end
