# frozen_string_literal: true

class CreateRailspressFocalPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_focal_points do |t|
      t.references :record, polymorphic: true, null: false, index: false
      t.string :attachment_name, null: false
      t.decimal :focal_x, precision: 5, scale: 4, default: 0.5, null: false
      t.decimal :focal_y, precision: 5, scale: 4, default: 0.5, null: false
      t.json :overrides, default: {}

      t.timestamps
    end

    add_index :railspress_focal_points,
              [:record_type, :record_id, :attachment_name],
              unique: true,
              name: "idx_focal_points_record_attachment"
  end
end
