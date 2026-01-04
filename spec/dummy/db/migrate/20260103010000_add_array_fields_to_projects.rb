# frozen_string_literal: true

class AddArrayFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :tech_stack, :json, default: [], null: false
    add_column :projects, :highlights, :json, default: [], null: false
  end
end
