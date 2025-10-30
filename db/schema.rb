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

ActiveRecord::Schema[8.0].define(version: 2025_10_30_125929) do
  create_table "card_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "card_id", null: false
    t.integer "repetitions", default: 0, null: false
    t.integer "lapses", default: 0, null: false
    t.integer "interval_days", default: 0, null: false
    t.decimal "ease_factor", precision: 5, scale: 2, default: "2.5", null: false
    t.datetime "due_at", default: -> { "NOW()" }, null: false
    t.integer "state", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_card_progresses_on_card_id"
    t.index ["state"], name: "index_card_progresses_on_state"
    t.index ["user_id", "card_id"], name: "index_card_progresses_on_user_id_and_card_id", unique: true
    t.index ["user_id", "due_at"], name: "index_card_progresses_on_user_id_and_due_at"
    t.index ["user_id"], name: "index_card_progresses_on_user_id"
  end

  create_table "cards", force: :cascade do |t|
    t.integer "deck_id", null: false
    t.integer "card_type", default: 0, null: false
    t.text "front_text", null: false
    t.text "back_text", null: false
    t.json "extras", default: {}, null: false
    t.boolean "suspended", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_type"], name: "index_cards_on_card_type"
    t.index ["deck_id"], name: "index_cards_on_deck_id"
    t.index ["suspended"], name: "index_cards_on_suspended"
  end

  create_table "deck_collaborators", force: :cascade do |t|
    t.integer "deck_id", null: false
    t.integer "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deck_id", "user_id"], name: "index_deck_collaborators_on_deck_id_and_user_id", unique: true
    t.index ["deck_id"], name: "index_deck_collaborators_on_deck_id"
    t.index ["user_id"], name: "index_deck_collaborators_on_user_id"
  end

  create_table "decks", force: :cascade do |t|
    t.integer "owner_id", null: false
    t.string "title", null: false
    t.text "description"
    t.boolean "is_public", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "title"], name: "index_decks_on_owner_id_and_title"
    t.index ["owner_id"], name: "index_decks_on_owner_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "card_id", null: false
    t.integer "rating", null: false
    t.integer "time_taken_ms", default: 0, null: false
    t.integer "scheduled_interval_days", default: 0, null: false
    t.integer "new_interval_days", default: 0, null: false
    t.decimal "new_ease_factor", precision: 5, scale: 2, default: "2.5", null: false
    t.datetime "reviewed_at", default: -> { "NOW()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_reviews_on_card_id"
    t.index ["user_id", "card_id", "reviewed_at"], name: "index_reviews_on_user_id_and_card_id_and_reviewed_at"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_taggings_on_card_id"
    t.index ["tag_id", "card_id"], name: "index_taggings_on_tag_id_and_card_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "display_name", null: false
    t.string "encrypted_password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "card_progresses", "cards"
  add_foreign_key "card_progresses", "users"
  add_foreign_key "cards", "decks"
  add_foreign_key "deck_collaborators", "decks"
  add_foreign_key "deck_collaborators", "users"
  add_foreign_key "decks", "users", column: "owner_id"
  add_foreign_key "reviews", "cards"
  add_foreign_key "reviews", "users"
  add_foreign_key "taggings", "cards"
  add_foreign_key "taggings", "tags"
end
