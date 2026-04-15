# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_15_000002) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "client"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false
    t.json "highlights", default: [], null: false
    t.json "tech_stack", default: [], null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "railspress_agent_bootstrap_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "created_by_type"
    t.bigint "exchanged_api_key_id"
    t.datetime "expires_at", null: false
    t.string "global_uuid", null: false
    t.string "name", null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "revoke_reason"
    t.datetime "revoked_at"
    t.bigint "revoked_by_id"
    t.string "revoked_by_type"
    t.text "secret_ciphertext", null: false
    t.string "token_digest", null: false
    t.string "token_prefix", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.string "used_ip"
    t.index ["created_by_type", "created_by_id"], name: "idx_rp_agent_bootstrap_keys_created_by"
    t.index ["exchanged_api_key_id"], name: "index_railspress_agent_bootstrap_keys_on_exchanged_api_key_id"
    t.index ["global_uuid"], name: "index_railspress_agent_bootstrap_keys_on_global_uuid", unique: true
    t.index ["owner_type", "owner_id"], name: "idx_rp_agent_bootstrap_keys_owner"
    t.index ["revoked_by_type", "revoked_by_id"], name: "idx_rp_agent_bootstrap_keys_revoked_by"
    t.index ["token_digest"], name: "index_railspress_agent_bootstrap_keys_on_token_digest", unique: true
    t.index ["token_prefix"], name: "index_railspress_agent_bootstrap_keys_on_token_prefix"
  end

  create_table "railspress_api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "created_by_type"
    t.datetime "expires_at"
    t.string "global_uuid", null: false
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.string "name", null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "revoke_reason"
    t.datetime "revoked_at"
    t.bigint "revoked_by_id"
    t.string "revoked_by_type"
    t.bigint "rotated_by_id"
    t.string "rotated_by_type"
    t.integer "rotated_from_id"
    t.text "secret_ciphertext", null: false
    t.string "token_digest", null: false
    t.string "token_prefix", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_type", "created_by_id"], name: "index_railspress_api_keys_on_created_by_type_and_created_by_id"
    t.index ["global_uuid"], name: "index_railspress_api_keys_on_global_uuid", unique: true
    t.index ["owner_type", "owner_id"], name: "index_railspress_api_keys_on_owner_type_and_owner_id"
    t.index ["revoked_by_type", "revoked_by_id"], name: "index_railspress_api_keys_on_revoked_by_type_and_revoked_by_id"
    t.index ["rotated_by_type", "rotated_by_id"], name: "index_railspress_api_keys_on_rotated_by_type_and_rotated_by_id"
    t.index ["rotated_from_id"], name: "index_railspress_api_keys_on_rotated_from_id"
    t.index ["token_digest"], name: "index_railspress_api_keys_on_token_digest", unique: true
    t.index ["token_prefix"], name: "index_railspress_api_keys_on_token_prefix"
  end

  create_table "railspress_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_railspress_categories_on_name", unique: true
    t.index ["slug"], name: "index_railspress_categories_on_slug", unique: true
  end

  create_table "railspress_content_element_versions", force: :cascade do |t|
    t.bigint "author_id"
    t.integer "content_element_id", null: false
    t.datetime "created_at", null: false
    t.text "text_content"
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["author_id"], name: "index_railspress_content_element_versions_on_author_id"
    t.index ["content_element_id", "version_number"], name: "idx_content_element_versions_unique", unique: true
    t.index ["content_element_id"], name: "idx_on_content_element_id_c4c667c695"
  end

  create_table "railspress_content_elements", force: :cascade do |t|
    t.bigint "author_id"
    t.integer "content_group_id", null: false
    t.integer "content_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "image_hint"
    t.string "name", null: false
    t.integer "position"
    t.boolean "required", default: false, null: false
    t.text "text_content"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_railspress_content_elements_on_author_id"
    t.index ["content_group_id", "name"], name: "idx_content_elements_unique_name_per_group", unique: true, where: "deleted_at IS NULL"
    t.index ["content_group_id"], name: "index_railspress_content_elements_on_content_group_id"
    t.index ["content_type"], name: "index_railspress_content_elements_on_content_type"
    t.index ["deleted_at"], name: "index_railspress_content_elements_on_deleted_at"
  end

  create_table "railspress_content_groups", force: :cascade do |t|
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_railspress_content_groups_on_author_id"
    t.index ["deleted_at"], name: "index_railspress_content_groups_on_deleted_at"
    t.index ["name"], name: "index_railspress_content_groups_on_name", unique: true
  end

  create_table "railspress_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "error_count", default: 0
    t.text "error_messages"
    t.string "export_type", null: false
    t.string "filename"
    t.string "status", default: "pending", null: false
    t.integer "success_count", default: 0
    t.integer "total_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["export_type"], name: "index_railspress_exports_on_export_type"
    t.index ["status"], name: "index_railspress_exports_on_status"
    t.index ["user_id"], name: "index_railspress_exports_on_user_id"
  end

  create_table "railspress_focal_points", force: :cascade do |t|
    t.string "attachment_name", null: false
    t.datetime "created_at", null: false
    t.decimal "focal_x", precision: 5, scale: 4, default: "0.5", null: false
    t.decimal "focal_y", precision: 5, scale: 4, default: "0.5", null: false
    t.json "overrides", default: {}
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "attachment_name"], name: "idx_focal_points_record_attachment", unique: true
  end

  create_table "railspress_imports", force: :cascade do |t|
    t.string "content_type"
    t.datetime "created_at", null: false
    t.integer "error_count", default: 0
    t.text "error_messages"
    t.string "filename"
    t.string "import_type", null: false
    t.string "status", default: "pending", null: false
    t.integer "success_count", default: 0
    t.integer "total_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["import_type"], name: "index_railspress_imports_on_import_type"
    t.index ["status"], name: "index_railspress_imports_on_status"
    t.index ["user_id"], name: "index_railspress_imports_on_user_id"
  end

  create_table "railspress_posts", force: :cascade do |t|
    t.bigint "author_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.text "meta_description"
    t.string "meta_title"
    t.datetime "published_at"
    t.integer "reading_time"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_railspress_posts_on_author_id"
    t.index ["category_id"], name: "index_railspress_posts_on_category_id"
    t.index ["published_at"], name: "index_railspress_posts_on_published_at"
    t.index ["slug"], name: "index_railspress_posts_on_slug", unique: true
    t.index ["status"], name: "index_railspress_posts_on_status"
  end

  create_table "railspress_taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.integer "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_unique", unique: true
    t.index ["tag_id"], name: "index_railspress_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_railspress_taggings_on_taggable"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "railspress_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_railspress_tags_on_name", unique: true
    t.index ["slug"], name: "index_railspress_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "railspress_content_element_versions", "railspress_content_elements", column: "content_element_id"
  add_foreign_key "railspress_content_elements", "railspress_content_groups", column: "content_group_id"
  add_foreign_key "railspress_posts", "railspress_categories", column: "category_id"
  add_foreign_key "railspress_taggings", "railspress_tags", column: "tag_id"
end
