# Custom RSpec matchers for verifying consistent view styling
# These matchers help ensure all entity views follow the established patterns

module ViewStylingMatchers
  # Matcher to verify a page has the correct index page structure
  RSpec::Matchers.define :have_rp_index_structure do
    match do |page|
      page.has_css?(".rp-page-header") &&
        page.has_css?(".rp-page-title") &&
        page.has_css?(".rp-page-actions") &&
        page.has_css?(".rp-btn.rp-btn--primary")
    end

    failure_message do
      "expected page to have RailsPress index structure (.rp-page-header, .rp-page-title, .rp-page-actions, .rp-btn--primary)"
    end
  end

  # Matcher to verify a table has correct structure
  RSpec::Matchers.define :have_rp_table_structure do
    match do |page|
      page.has_css?(".rp-card") &&
        page.has_css?(".rp-table--responsive") &&
        page.has_css?(".rp-table") &&
        page.has_css?(".rp-table-actions")
    end

    failure_message do
      "expected page to have RailsPress table structure (.rp-card > .rp-table--responsive > .rp-table, .rp-table-actions)"
    end
  end

  # Matcher to verify a form has correct structure
  RSpec::Matchers.define :have_rp_form_structure do |type = :simple|
    match do |page|
      base_structure = page.has_css?("form.rp-form") &&
        page.has_css?(".rp-form-group") &&
        page.has_css?(".rp-form-actions") &&
        page.has_css?("input.rp-btn.rp-btn--primary, button.rp-btn.rp-btn--primary") &&
        page.has_css?("a.rp-btn.rp-btn--secondary")

      case type
      when :simple
        base_structure && page.has_css?("form.rp-form.rp-form--narrow")
      when :complex
        base_structure && page.has_css?(".rp-form-layout") &&
          page.has_css?(".rp-form-main") &&
          page.has_css?(".rp-form-sidebar")
      else
        base_structure
      end
    end

    failure_message do
      case type
      when :simple
        "expected page to have simple RailsPress form structure (.rp-form.rp-form--narrow)"
      when :complex
        "expected page to have complex RailsPress form structure (.rp-form-layout, .rp-form-main, .rp-form-sidebar)"
      else
        "expected page to have RailsPress form structure (form.rp-form, .rp-form-group, .rp-form-actions)"
      end
    end
  end

  # Matcher to verify inputs have correct styling
  RSpec::Matchers.define :have_rp_input_styling do
    match do |page|
      page.has_css?("input.rp-input, textarea.rp-input") &&
        page.has_css?("label.rp-label")
    end

    failure_message do
      "expected page to have RailsPress input styling (input.rp-input, label.rp-label)"
    end
  end

  # Matcher to verify page title is standalone (for new/edit pages)
  RSpec::Matchers.define :have_rp_standalone_title do
    match do |page|
      page.has_css?("h1.rp-page-title.rp-page-title--standalone")
    end

    failure_message do
      "expected page to have standalone page title (h1.rp-page-title.rp-page-title--standalone)"
    end
  end

  # Matcher to verify delete actions use proper styling
  RSpec::Matchers.define :have_rp_delete_styling do
    match do |page|
      page.has_css?(".rp-link.rp-link--danger") ||
        page.has_css?("button.rp-link.rp-link--danger") ||
        page.has_css?("input.rp-link.rp-link--danger")
    end

    failure_message do
      "expected page to have properly styled delete action (.rp-link.rp-link--danger)"
    end
  end

  # Matcher to verify empty state styling
  RSpec::Matchers.define :have_rp_empty_state do
    match do |page|
      page.has_css?(".rp-empty-state")
    end

    failure_message do
      "expected page to have RailsPress empty state (.rp-empty-state)"
    end
  end

  # Matcher to verify select dropdowns have correct styling
  RSpec::Matchers.define :have_rp_select_styling do
    match do |page|
      page.has_css?("select.rp-select")
    end

    failure_message do
      "expected page to have RailsPress select styling (select.rp-select)"
    end
  end
end

RSpec.configure do |config|
  config.include ViewStylingMatchers, type: :system
  config.include ViewStylingMatchers, type: :feature
end
