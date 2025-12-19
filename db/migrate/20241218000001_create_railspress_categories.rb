class CreateRailspressCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :railspress_categories, :name, unique: true
    add_index :railspress_categories, :slug, unique: true
  end
end
