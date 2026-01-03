namespace :railspress do
  desc "Migrate post_tags to polymorphic taggings table (one-time migration)"
  task migrate_tags: :environment do
    puts "Starting tag migration from post_tags to taggings..."

    # Check if PostTag table exists
    unless ActiveRecord::Base.connection.table_exists?(:railspress_post_tags)
      puts "No post_tags table found. Nothing to migrate."
      next
    end

    old_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM railspress_post_tags").to_i

    if old_count == 0
      puts "No post_tags to migrate. Done!"
      next
    end

    puts "Found #{old_count} post_tags to migrate"

    ActiveRecord::Base.transaction do
      # Use raw SQL to avoid dependency on PostTag model
      results = ActiveRecord::Base.connection.select_all(
        "SELECT post_id, tag_id FROM railspress_post_tags"
      )

      results.each do |row|
        Railspress::Tagging.find_or_create_by!(
          tag_id: row["tag_id"],
          taggable_type: "Railspress::Post",
          taggable_id: row["post_id"]
        )
      end

      new_count = Railspress::Tagging.where(taggable_type: "Railspress::Post").count

      if new_count != old_count
        raise "Count mismatch! Expected #{old_count}, got #{new_count}. Rolling back."
      end

      puts "Successfully migrated #{new_count} taggings"
    end

    puts "\nMigration complete!"
    puts "You can now safely drop the post_tags table."
    puts "Run the drop migration or execute:"
    puts "  rails generate migration DropRailspressPostTags"
  end
end
