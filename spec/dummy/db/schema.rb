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

ActiveRecord::Schema[8.1].define(version: 2024_12_18_000004) do
  create_table "railspress_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_railspress_categories_on_name", unique: true
    t.index ["slug"], name: "index_railspress_categories_on_slug", unique: true
  end

  create_table "railspress_post_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_railspress_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_railspress_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_railspress_post_tags_on_tag_id"
  end

  create_table "railspress_posts", force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.text "meta_description"
    t.string "meta_title"
    t.datetime "published_at"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_railspress_posts_on_category_id"
    t.index ["published_at"], name: "index_railspress_posts_on_published_at"
    t.index ["slug"], name: "index_railspress_posts_on_slug", unique: true
    t.index ["status"], name: "index_railspress_posts_on_status"
  end

  create_table "railspress_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_railspress_tags_on_name", unique: true
    t.index ["slug"], name: "index_railspress_tags_on_slug", unique: true
  end

  add_foreign_key "railspress_post_tags", "railspress_posts", column: "post_id"
  add_foreign_key "railspress_post_tags", "railspress_tags", column: "tag_id"
  add_foreign_key "railspress_posts", "railspress_categories", column: "category_id"
end
