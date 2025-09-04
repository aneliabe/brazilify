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

ActiveRecord::Schema[7.1].define(version: 2025_08_30_190636) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string "status"
    t.bigint "user_id", null: false
    t.bigint "worker_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "client_last_read_at"
    t.datetime "worker_last_read_at"
    t.datetime "proposed_starts_at"
    t.bigint "proposed_by_id"
    t.index ["proposed_by_id"], name: "index_appointments_on_proposed_by_id"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["user_id", "created_at"], name: "index_appointments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_appointments_on_user_id"
    t.index ["worker_profile_id", "starts_at"], name: "index_appointments_on_worker_profile_id_and_starts_at"
    t.index ["worker_profile_id"], name: "index_appointments_on_worker_profile_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id", null: false
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_messages_on_appointment_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "worker_profile_id", null: false
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "worker_profile_id"], name: "index_reviews_on_user_id_and_worker_profile_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.index ["worker_profile_id"], name: "index_reviews_on_worker_profile_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "name"], name: "index_services_on_category_id_and_name", unique: true
    t.index ["category_id"], name: "index_services_on_category_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.text "channel"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "address"
    t.date "birth_date"
    t.string "phone"
    t.string "country"
    t.string "city"
    t.string "avatar"
    t.integer "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "worker_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "cpf"
    t.text "description"
    t.decimal "rating", precision: 3, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_worker_profiles_on_category_id"
    t.index ["user_id"], name: "index_worker_profiles_on_user_id"
  end

  create_table "worker_services", force: :cascade do |t|
    t.bigint "worker_profile_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "service_type"
    t.bigint "category_id"
    t.index ["category_id"], name: "index_worker_services_on_category_id"
    t.index ["service_id"], name: "index_worker_services_on_service_id"
    t.index ["worker_profile_id", "service_id"], name: "index_worker_services_on_worker_profile_id_and_service_id", unique: true
    t.index ["worker_profile_id"], name: "index_worker_services_on_worker_profile_id"
  end

  add_foreign_key "appointments", "users"
  add_foreign_key "appointments", "users", column: "proposed_by_id"
  add_foreign_key "appointments", "worker_profiles"
  add_foreign_key "messages", "appointments"
  add_foreign_key "messages", "users"
  add_foreign_key "reviews", "users"
  add_foreign_key "reviews", "worker_profiles"
  add_foreign_key "services", "categories"
  add_foreign_key "worker_profiles", "categories"
  add_foreign_key "worker_profiles", "users"
  add_foreign_key "worker_services", "categories"
  add_foreign_key "worker_services", "services"
  add_foreign_key "worker_services", "worker_profiles"
end
