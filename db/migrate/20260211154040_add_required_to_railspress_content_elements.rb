class AddRequiredToRailspressContentElements < ActiveRecord::Migration[8.1]
  def change
    add_column :railspress_content_elements, :required, :boolean, default: false, null: false
  end
end
