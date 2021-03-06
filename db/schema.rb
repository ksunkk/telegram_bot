# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_06_05_193352) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.text "address"
    t.text "source"
    t.integer "added_by"
    t.boolean "is_deleted", default: false
    t.boolean "is_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "check_status", default: 2
  end

  create_table "photos", force: :cascade do |t|
    t.oid "photo", null: false
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_photos_on_organization_id"
  end

  create_table "roles_permissions", force: :cascade do |t|
    t.bigint "telegram_role_id"
    t.bigint "telegram_permission_id"
    t.index ["telegram_permission_id"], name: "index_roles_permissions_on_telegram_permission_id"
    t.index ["telegram_role_id"], name: "index_roles_permissions_on_telegram_role_id"
  end

  create_table "statistics", force: :cascade do |t|
    t.integer "valid_count", default: 0
    t.integer "invalid_count", default: 0
    t.bigint "telegram_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "corrections_count"
    t.integer "validates_count"
    t.integer "dubles_count", default: 0
    t.index ["telegram_user_id"], name: "index_statistics_on_telegram_user_id"
  end

  create_table "telegram_permissions", force: :cascade do |t|
    t.string "action_name"
    t.string "name"
    t.boolean "is_deleted", default: false
  end

  create_table "telegram_roles", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "is_deleted", default: "f"
  end

  create_table "telegram_users", force: :cascade do |t|
    t.integer "telegram_role_id"
    t.string "phone"
    t.string "name"
    t.boolean "is_deleted", default: false
    t.boolean "is_verificated", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "telegram_id"
    t.integer "statistic_id"
    t.integer "chat_id"
  end

end
