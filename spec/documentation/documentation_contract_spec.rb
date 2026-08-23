# frozen_string_literal: true

require "rails_helper"
require "json"

RSpec.describe "Packaged documentation contracts" do
  engine_root = Railspress::Engine.root
  markdown_files = [ engine_root.join("README.md"), engine_root.join("CHANGELOG.md") ] +
    Dir[engine_root.join("docs/**/*.md")].map { |path| Pathname(path) }

  def prose_from(path)
    in_fence = false

    path.each_line.filter_map do |line|
      if line.lstrip.start_with?("```")
        in_fence = !in_fence
        next
      end

      line unless in_fence
    end.join
  end

  it "does not contain broken local Markdown links" do
    failures = []

    markdown_files.each do |path|
      prose_from(path).scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |destination|
        next if destination == "url" || destination.match?(/\A(?:https?:|mailto:|#)/)

        relative_path = destination.delete_prefix("<").delete_suffix(">").split("#", 2).first
        target = relative_path.start_with?("/") ? engine_root.join(relative_path.delete_prefix("/")) : path.dirname.join(relative_path)
        failures << "#{path.relative_path_from(engine_root)} -> #{destination}" unless target.exist?
      end
    end

    expect(failures).to be_empty, "Broken local links:\n#{failures.join("\n")}"
  end

  it "documents every RailsPress view helper" do
    helper_names = [ Railspress::AdminHelper, Railspress::ApplicationHelper ].flat_map do |helper_module|
      helper_module.public_instance_methods(false).grep(/\Arp_/)
    end.map(&:to_s).sort
    documentation = engine_root.join("docs/ADMIN_HELPERS.md").read

    expect(helper_names).to all(satisfy { |name| documentation.include?("`#{name}") })
  end

  it "keeps the theming token inventory synchronized with CSS" do
    css = engine_root.join("app/assets/stylesheets/railspress/admin/variables.css").read
    guide = engine_root.join("docs/THEMING.md").read
    css_tokens = css.scan(/(--rp-[a-z0-9-]+)\s*:/).flatten.uniq.sort
    documented_tokens = guide.scan(/`(--rp-[a-z0-9-]+)`/).flatten.uniq.sort

    expect(documented_tokens).to eq(css_tokens)
  end

  it "covers every public host configuration option" do
    public_options = %w[
      enable_authors enable_post_images enable_post_previews enable_focal_points enable_cms enable_api
      author_class_name current_author_method current_author_proc author_scope author_display_method
      admin_authentication_method current_admin_method current_admin_proc admin_auth_concern public_base_url
      words_per_minute blog_path post_preview_expires_in default_index_columns post_image_variants inline_editing_check
      image_contexts add_image_context remove_image_context register_entity
    ]
    guide = engine_root.join("docs/CONFIGURING.md").read

    expect(public_options).to all(satisfy { |option| guide.include?("`#{option}`") })
  end

  it "keeps documented engine route helpers available" do
    helpers = Railspress::Engine.routes.url_helpers
    guide_helpers = markdown_files.flat_map do |path|
      path.read.scan(/railspress\.([a-z][a-z0-9_]*_path)/).flatten
    end.uniq
    reference_helpers = %w[
      admin_cms_transfer_path export_admin_cms_transfer_path import_admin_cms_transfer_path
      admin_entity_index_path admin_entity_path admin_new_entity_path admin_edit_entity_path
      typed_admin_imports_path typed_admin_exports_path download_admin_export_path
      admin_api_keys_path new_admin_api_key_path new_admin_agent_bootstrap_key_path
    ]

    expect(guide_helpers + reference_helpers).to all(satisfy { |helper| helpers.respond_to?(helper) })
  end

  it "documents every RailsPress maintenance task" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("railspress:doctor")
    task_names = %w[
      railspress:doctor railspress:upgrade railspress:install:migrations railspress:migrate_tags
    ]
    guide = engine_root.join("docs/MAINTENANCE.md").read

    expect(task_names).to all(satisfy do |task_name|
      Rake::Task.task_defined?(task_name) && guide.include?("`#{task_name}`")
    end)
  end

  it "keeps the Prime response example aligned with its public shape" do
    guide = engine_root.join("docs/api/prime.md").read
    json = guide.match(/## Response shape.*?```json\n(.*?)```/m)[1]
    data = JSON.parse(json).fetch("data")

    expect(data.keys).to contain_exactly(
      "service", "version", "authentication", "defaults", "capabilities", "endpoints", "key", "server_time"
    )
    expect(data.fetch("capabilities").keys).to contain_exactly(
      "posts", "post_imports", "post_media", "taxonomies"
    )
    expect(data.fetch("capabilities").fetch("posts").fetch("content_formats")).to eq(
      Railspress::PostContentFormatter::SUPPORTED_FORMATS
    )
    expect(data.fetch("key").keys).to contain_exactly(
      "id", "name", "status", "expires_at", "last_used_at"
    )
  end

  it "documents the CLI-first RailsPress Agent onboarding contract" do
    readme = engine_root.join("README.md").read
    api_readme = engine_root.join("docs/api/README.md").read
    bootstrap_guide = engine_root.join("docs/api/agent_bootstrap_keys.md").read
    authentication_guide = engine_root.join("docs/api/authentication.md").read

    expect(readme).to include("https://agent.railspress.org/install.sh")
    expect(api_readme).to include("railspress-agent", "onboard", "RAILSPRESS.md")
    expect(bootstrap_guide).to include("railspress-agent", "onboard", "exchange_outcome_unknown")
    expect(authentication_guide).to include("railspress-agent", "prime", "atomically claimed")
    expect([ bootstrap_guide, authentication_guide ].join).not_to include('> "$RAILSPRESS_TOKEN_FILE"')
  end

  it "keeps Post and header-media examples aligned with their public shapes" do
    posts_guide = engine_root.join("docs/api/posts.md").read
    post_json = posts_guide.match(/Single resource:.*?```json\n(.*?)```/m)[1]
    post_data = JSON.parse(post_json).fetch("data")
    media_guide = engine_root.join("docs/api/post_media.md").read
    media_json = media_guide.match(/An attached image returns:.*?```json\n(.*?)```/m)[1]
    media_data = JSON.parse(media_json).fetch("data")

    expect(post_data.keys).to contain_exactly(
      "id", "title", "slug", "status", "published_at", "reading_time", "meta_title", "meta_description",
      "category_id", "author_id", "author_display", "tag_list", "content", "content_format", "header_image",
      "gallery_images", "header_image_focal_point", "created_at", "updated_at"
    )
    expect(media_data.keys).to contain_exactly("post_id", "header_image", "header_image_focal_point")
    expect(media_data.fetch("header_image").keys).to contain_exactly(
      "attached", "blob_id", "signed_blob_id", "filename", "byte_size", "content_type"
    )
  end
end
