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

ActiveRecord::Schema[8.1].define(version: 2026_05_10_222608) do
  create_table "masteries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id", null: false
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

  create_table "skill_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "external_group_code", null: false
    t.string "icon_path"
    t.integer "mastery_id", null: false
    t.string "name"
    t.string "tooltip"
    t.datetime "updated_at", null: false
    t.index ["external_group_code"],
            name: "index_skill_groups_on_external_group_code",
            unique: true
    t.index ["mastery_id"], name: "index_skill_groups_on_mastery_id"
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
    t.integer "skill_group_id", null: false
    t.integer "skill_level", null: false
    t.integer "sp_cost"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_skills_on_external_id", unique: true
    t.index ["external_skill_code"],
            name: "index_skills_on_external_skill_code",
            unique: true
    t.index ["skill_group_id"], name: "index_skills_on_skill_group_id"
  end

  add_foreign_key "masteries", "races"
  add_foreign_key "skill_groups", "masteries"
  add_foreign_key "skill_series", "masteries"
end
