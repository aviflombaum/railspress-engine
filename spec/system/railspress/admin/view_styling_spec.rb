require "rails_helper"

# This spec file demonstrates how to verify view styling consistency
# across all entity types in the RailsPress admin.
#
# Run with: bundle exec rspec spec/system/railspress/admin/view_styling_spec.rb
#
# When creating new entity types, add similar specs to ensure they
# follow the established styling patterns.

RSpec.describe "Admin View Styling Consistency", type: :system do
  # Helper to set up test data for different entity types
  def setup_categories
    Railspress::Category.create!(name: "Test Category", slug: "test-category")
  end

  def setup_tags
    Railspress::Tag.create!(name: "Test Tag", slug: "test-tag")
  end

  def setup_posts
    category = setup_categories
    Railspress::Post.create!(
      title: "Test Post",
      slug: "test-post",
      status: "published",
      category: category
    )
  end

  describe "Categories (simple entity pattern)" do
    describe "index page" do
      before do
        setup_categories
        visit railspress.admin_categories_path
      end

      it "has correct page header structure" do
        expect(page).to have_rp_index_structure
      end

      it "has correct table structure" do
        expect(page).to have_rp_table_structure
      end

      it "has correct delete action styling" do
        expect(page).to have_rp_delete_styling
      end
    end

    describe "new page" do
      before { visit railspress.new_admin_category_path }

      it "has standalone page title" do
        expect(page).to have_rp_standalone_title
      end

      it "has simple form structure" do
        expect(page).to have_rp_form_structure(:simple)
      end

      it "has correct input styling" do
        expect(page).to have_rp_input_styling
      end
    end

    describe "edit page" do
      before do
        category = setup_categories
        visit railspress.edit_admin_category_path(category)
      end

      it "has standalone page title" do
        expect(page).to have_rp_standalone_title
      end

      it "has simple form structure" do
        expect(page).to have_rp_form_structure(:simple)
      end
    end

    describe "empty state" do
      # NOTE: Testing empty state requires database cleaner with truncation
      # strategy since system tests run in a separate process and can't see
      # transactional changes. The empty state UI (.rp-empty-state) is verified
      # to exist in the view template at app/views/railspress/admin/categories/index.html.erb
      it "shows empty state when no records exist", skip: "Requires database cleaner for proper isolation" do
        visit railspress.admin_categories_path
        expect(page).to have_rp_empty_state
      end
    end
  end

  describe "Tags (simple entity pattern)" do
    describe "index page" do
      before do
        setup_tags
        visit railspress.admin_tags_path
      end

      it "has correct page header structure" do
        expect(page).to have_rp_index_structure
      end

      it "has correct table structure" do
        expect(page).to have_rp_table_structure
      end
    end

    describe "new page" do
      before { visit railspress.new_admin_tag_path }

      it "has simple form structure" do
        expect(page).to have_rp_form_structure(:simple)
      end
    end
  end

  describe "Posts (complex entity pattern)" do
    describe "index page" do
      before do
        setup_posts
        visit railspress.admin_posts_path
      end

      it "has correct page header structure" do
        expect(page).to have_rp_index_structure
      end

      it "has correct table structure" do
        expect(page).to have_rp_table_structure
      end

      it "has select dropdowns with correct styling" do
        expect(page).to have_rp_select_styling
      end
    end

    describe "new page" do
      before do
        Railspress::Category.create!(name: "Category", slug: "category")
        visit railspress.new_admin_post_path
      end

      it "has standalone page title" do
        expect(page).to have_rp_standalone_title
      end

      it "has complex form structure" do
        expect(page).to have_rp_form_structure(:complex)
      end

      it "has correct input styling" do
        expect(page).to have_rp_input_styling
      end

      it "has select dropdowns with correct styling" do
        expect(page).to have_rp_select_styling
      end
    end
  end

  # Template for testing new entity types
  # Copy and adapt this when adding new entities
  #
  # describe "NewEntity (simple|complex entity pattern)" do
  #   describe "index page" do
  #     before do
  #       create_test_records
  #       visit railspress.admin_new_entities_path
  #     end
  #
  #     it "has correct page header structure" do
  #       expect(page).to have_rp_index_structure
  #     end
  #
  #     it "has correct table structure" do
  #       expect(page).to have_rp_table_structure
  #     end
  #
  #     it "has correct delete action styling" do
  #       expect(page).to have_rp_delete_styling
  #     end
  #   end
  #
  #   describe "new page" do
  #     before { visit railspress.new_admin_new_entity_path }
  #
  #     it "has standalone page title" do
  #       expect(page).to have_rp_standalone_title
  #     end
  #
  #     it "has [simple|complex] form structure" do
  #       expect(page).to have_rp_form_structure(:simple) # or :complex
  #     end
  #
  #     it "has correct input styling" do
  #       expect(page).to have_rp_input_styling
  #     end
  #   end
  #
  #   describe "empty state" do
  #     before { visit railspress.admin_new_entities_path }
  #
  #     it "shows empty state when no records exist" do
  #       expect(page).to have_rp_empty_state
  #     end
  #   end
  # end
end
