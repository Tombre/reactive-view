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

ActiveRecord::Schema[8.0].define(version: 2026_03_05_050000) do
  create_table "account_webauthn_keys", id: false, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "webauthn_id", null: false
    t.string "public_key", null: false
    t.integer "sign_count", null: false
    t.datetime "last_use"
    t.index ["account_id", "webauthn_id"], name: "index_account_webauthn_keys_on_account_id_and_webauthn_id", unique: true
  end

  create_table "account_webauthn_user_ids", force: :cascade do |t|
    t.string "webauthn_id", null: false
    t.index ["webauthn_id"], name: "index_account_webauthn_user_ids_on_webauthn_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "account_webauthn_keys", "users", column: "account_id", on_delete: :cascade
  add_foreign_key "account_webauthn_user_ids", "users", column: "id", on_delete: :cascade
end
