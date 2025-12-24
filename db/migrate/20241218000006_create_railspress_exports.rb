class CreateRailspressExports < ActiveRecord::Migration[7.1]
  def change
    create_table :railspress_exports do |t|
      t.string :export_type, null: false
      t.string :filename
      t.string :status, default: "pending", null: false
      t.integer :total_count, default: 0
      t.integer :success_count, default: 0
      t.integer :error_count, default: 0
      t.text :error_messages
      t.bigint :user_id

      t.timestamps
    end

    add_index :railspress_exports, :export_type
    add_index :railspress_exports, :status
    add_index :railspress_exports, :user_id
  end
end
