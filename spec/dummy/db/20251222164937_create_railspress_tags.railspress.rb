# This migration comes from railspress (originally 20241218000002)
class CreateRailspressTags < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_tags do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :railspress_tags, :name, unique: true
    add_index :railspress_tags, :slug, unique: true
  end
end
