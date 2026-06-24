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

ActiveRecord::Schema[8.1].define(version: 2026_06_23_073839) do
  create_table "character_masteries", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "current_mastery_level"
    t.integer "mastery_id", null: false
    t.integer "target_mastery_level"
    t.datetime "updated_at", null: false
    t.index %w[character_id mastery_id],
            name: "index_character_masteries_on_character_id_and_mastery_id",
            unique: true
    t.index ["character_id"], name: "index_character_masteries_on_character_id"
    t.index ["mastery_id"], name: "index_character_masteries_on_mastery_id"
  end

  create_table "character_skills", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "current_skill_level"
    t.integer "skill_group_id", null: false
    t.integer "target_skill_level"
    t.datetime "updated_at", null: false
    t.index %w[character_id skill_group_id],
            name: "index_character_skills_on_character_id_and_skill_group_id",
            unique: true
    t.index ["character_id"], name: "index_character_skills_on_character_id"
    t.index ["skill_group_id"], name: "index_character_skills_on_skill_group_id"
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_level"
    t.string "name"
    t.integer "race_id", null: false
    t.integer "server_level_cap", default: 110, null: false
    t.integer "target_level"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["race_id"], name: "index_characters_on_race_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "level_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level"
    t.integer "sp_cumulative"
    t.integer "sp_gained"
    t.datetime "updated_at", null: false
    t.integer "xp_required"
  end

  create_table "masteries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id", null: false
    t.string "icon_path"
    t.string "mastery_type", null: false
    t.string "name", null: false
    t.integer "race_id", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"],
            name: "index_masteries_on_external_id",
            unique: true
    t.index ["race_id"], name: "index_masteries_on_race_id"
  end

  create_table "races", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_races_on_external_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "skill_group_requirements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "required_group_id", null: false
    t.integer "required_skill_level"
    t.integer "skill_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["required_group_id"],
            name: "index_skill_group_requirements_on_required_group_id"
    t.index ["skill_group_id"],
            name: "index_skill_group_requirements_on_skill_group_id"
  end

  create_table "skill_groups", force: :cascade do |t|
    t.integer "col_position"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "external_group_code", null: false
    t.integer "external_id"
    t.string "icon_path"
    t.integer "mastery_id", null: false
    t.integer "max_skill_level"
    t.string "name"
    t.integer "skill_series_id"
    t.string "tooltip"
    t.datetime "updated_at", null: false
    t.index ["external_group_code"],
            name: "index_skill_groups_on_external_group_code",
            unique: true
    t.index ["mastery_id"], name: "index_skill_groups_on_mastery_id"
    t.index ["skill_series_id"], name: "index_skill_groups_on_skill_series_id"
  end

  create_table "skill_series", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon_path"
    t.integer "mastery_id", null: false
    t.integer "row_position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["mastery_id"], name: "index_skill_series_on_mastery_id"
  end

  create_table "skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id", null: false
    t.string "external_skill_code", null: false
    t.integer "mastery_level_req"
    t.integer "mp_cost"
    t.integer "skill_group_id", null: false
    t.integer "skill_level", null: false
    t.integer "sp_cost"
    t.integer "stack"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_skills_on_external_id", unique: true
    t.index ["external_skill_code"],
            name: "index_skills_on_external_skill_code",
            unique: true
    t.index ["skill_group_id"], name: "index_skills_on_skill_group_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "email_confirmed_at"
    t.boolean "email_opt_in", default: false, null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"],
            name: "index_users_on_email_address",
            unique: true
  end

  add_foreign_key "character_masteries", "characters"
  add_foreign_key "character_masteries", "masteries"
  add_foreign_key "character_skills", "characters"
  add_foreign_key "character_skills", "skill_groups"
  add_foreign_key "characters", "races"
  add_foreign_key "characters", "users"
  add_foreign_key "masteries", "races"
  add_foreign_key "sessions", "users"
  add_foreign_key "skill_group_requirements", "skill_groups"
  add_foreign_key "skill_group_requirements",
                  "skill_groups",
                  column: "required_group_id"
  add_foreign_key "skill_groups", "masteries"
  add_foreign_key "skill_groups", "skill_series"
  add_foreign_key "skill_series", "masteries"
end
