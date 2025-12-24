class AddReadingTimeToRailspressPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :railspress_posts, :reading_time, :integer
  end
end
