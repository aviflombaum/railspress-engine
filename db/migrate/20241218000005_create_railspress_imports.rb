class CreateRailspressImports < ActiveRecord::Migration[7.1]
  def change
    create_table :railspress_imports do |t|
      t.string :import_type, null: false
      t.string :filename
      t.string :content_type
      t.string :status, default: "pending", null: false
      t.integer :total_count, default: 0
      t.integer :success_count, default: 0
      t.integer :error_count, default: 0
      t.text :error_messages
      t.bigint :user_id

      t.timestamps
    end

    add_index :railspress_imports, :import_type
    add_index :railspress_imports, :status
    add_index :railspress_imports, :user_id
  end
end
