# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.string :client
      t.text :description
      t.boolean :featured, default: false

      t.timestamps
    end
  end
end
