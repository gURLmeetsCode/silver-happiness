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

ActiveRecord::Schema[8.0].define(version: 2026_08_08_190000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "daily_logs", force: :cascade do |t|
    t.date "logged_on", null: false
    t.decimal "weight_kg", precision: 8, scale: 2
    t.boolean "weight_pre_run", default: true, null: false
    t.decimal "run_km", precision: 8, scale: 2
    t.integer "run_calories"
    t.decimal "walk_km", precision: 8, scale: 2
    t.integer "walk_calories"
    t.text "training_notes"
    t.text "notes"
    t.text "energy_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "on_period", default: false, null: false
    t.integer "water_ml", default: 0, null: false
    t.time "bed_time"
    t.time "wake_time"
    t.integer "sleep_quality"
    t.text "feeling_check_in"
    t.index ["logged_on"], name: "index_daily_logs_on_logged_on", unique: true
  end

  create_table "goals", force: :cascade do |t|
    t.decimal "target_weight_kg", precision: 8, scale: 2, default: "56.0", null: false
    t.decimal "starting_weight_kg", precision: 8, scale: 2
    t.integer "protein_min_g", default: 90, null: false
    t.integer "protein_max_g", default: 100, null: false
    t.integer "calories_training_day", default: 1700, null: false
    t.integer "calories_rest_day", default: 1600, null: false
    t.date "target_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "water_goal_ml", default: 2000, null: false
  end

  create_table "grocery_checks", force: :cascade do |t|
    t.date "shopping_period", null: false
    t.string "item_key", null: false
    t.boolean "checked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shopping_period", "item_key"], name: "index_grocery_checks_on_shopping_period_and_item_key", unique: true
  end

  create_table "meal_entries", force: :cascade do |t|
    t.integer "daily_log_id", null: false
    t.integer "meal_template_id"
    t.integer "meal_type", default: 0, null: false
    t.string "name", null: false
    t.integer "calories", default: 0, null: false
    t.decimal "protein_g", precision: 8, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "carbs_g", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "fat_g", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "water_suggestion_ml", default: 250, null: false
    t.integer "water_logged_ml", default: 0, null: false
    t.index ["daily_log_id"], name: "index_meal_entries_on_daily_log_id"
    t.index ["meal_template_id"], name: "index_meal_entries_on_meal_template_id"
  end

  create_table "meal_template_items", force: :cascade do |t|
    t.integer "meal_template_id", null: false
    t.integer "product_id", null: false
    t.decimal "quantity_g", precision: 8, scale: 2, null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_template_id"], name: "index_meal_template_items_on_meal_template_id"
    t.index ["product_id"], name: "index_meal_template_items_on_product_id"
  end

  create_table "meal_templates", force: :cascade do |t|
    t.string "name"
    t.integer "meal_type"
    t.text "description"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "water_suggestion_ml", default: 250, null: false
    t.index ["slug"], name: "index_meal_templates_on_slug", unique: true
  end

  create_table "outfit_photos", force: :cascade do |t|
    t.date "logged_on", null: false
    t.integer "category", default: 0, null: false
    t.text "caption"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["logged_on", "category"], name: "index_outfit_photos_on_logged_on_and_category"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "brand"
    t.decimal "calories_per_100g", precision: 8, scale: 2, default: "0.0"
    t.decimal "protein_per_100g", precision: 8, scale: 2, default: "0.0"
    t.decimal "carbs_per_100g", precision: 8, scale: 2, default: "0.0"
    t.decimal "fat_per_100g", precision: 8, scale: 2, default: "0.0"
    t.decimal "default_serving_g", precision: 8, scale: 2
    t.string "serving_label"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "barcode"
    t.boolean "quick_log", default: false, null: false
    t.boolean "beverage", default: false, null: false
    t.integer "water_volume_ml"
    t.index ["barcode"], name: "index_products_on_barcode"
    t.index ["beverage"], name: "index_products_on_beverage"
    t.index ["quick_log"], name: "index_products_on_quick_log"
  end

  create_table "progress_photos", force: :cascade do |t|
    t.integer "daily_log_id", null: false
    t.integer "photo_type"
    t.text "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_log_id"], name: "index_progress_photos_on_daily_log_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.string "name", null: false
    t.string "amount"
    t.integer "grocery_category", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "product_id"
    t.decimal "quantity_g", precision: 8, scale: 2
    t.index ["product_id"], name: "index_recipe_ingredients_on_product_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "meal_type", default: 0, null: false
    t.text "description"
    t.text "steps"
    t.string "prep_time"
    t.integer "serves", default: 1
    t.integer "protein_g"
    t.integer "calories"
    t.boolean "regular_meal", default: true, null: false
    t.integer "position", default: 0, null: false
    t.integer "meal_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reaction", default: 0, null: false
    t.text "personal_notes"
    t.integer "status", default: 0, null: false
    t.boolean "user_created", default: false, null: false
    t.integer "water_suggestion_ml", default: 250, null: false
    t.index ["meal_template_id"], name: "index_recipes_on_meal_template_id"
    t.index ["slug"], name: "index_recipes_on_slug", unique: true
  end

  create_table "strength_exercise_logs", force: :cascade do |t|
    t.integer "strength_session_id", null: false
    t.string "name", null: false
    t.string "equipment"
    t.decimal "weight_kg", precision: 8, scale: 2
    t.integer "sets"
    t.string "reps"
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["strength_session_id"], name: "index_strength_exercise_logs_on_strength_session_id"
  end

  create_table "strength_sessions", force: :cascade do |t|
    t.integer "daily_log_id", null: false
    t.integer "workout_plan_id"
    t.integer "location", default: 0, null: false
    t.integer "perceived_difficulty"
    t.text "notes"
    t.integer "duration_min"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "calories_burned"
    t.index ["daily_log_id"], name: "index_strength_sessions_on_daily_log_id"
    t.index ["workout_plan_id"], name: "index_strength_sessions_on_workout_plan_id"
  end

  create_table "workout_plan_exercises", force: :cascade do |t|
    t.integer "workout_plan_id", null: false
    t.string "name", null: false
    t.string "sets_prescription"
    t.string "reps_prescription"
    t.string "equipment_hint"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "body_target"
    t.index ["workout_plan_id"], name: "index_workout_plan_exercises_on_workout_plan_id"
  end

  create_table "workout_plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "location", default: 0, null: false
    t.integer "scheduled_wday"
    t.text "description"
    t.string "duration_hint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "plan_kind", default: 0, null: false
    t.integer "suggested_wday"
    t.string "body_targets"
    t.index ["slug"], name: "index_workout_plans_on_slug", unique: true
  end

  create_table "workouts", force: :cascade do |t|
    t.integer "daily_log_id", null: false
    t.integer "activity_type", default: 0, null: false
    t.decimal "distance_km", precision: 8, scale: 2
    t.integer "calories_burned", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_log_id"], name: "index_workouts_on_daily_log_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "meal_entries", "daily_logs"
  add_foreign_key "meal_entries", "meal_templates"
  add_foreign_key "meal_template_items", "meal_templates"
  add_foreign_key "meal_template_items", "products"
  add_foreign_key "progress_photos", "daily_logs"
  add_foreign_key "recipe_ingredients", "products"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipes", "meal_templates"
  add_foreign_key "strength_exercise_logs", "strength_sessions"
  add_foreign_key "strength_sessions", "daily_logs"
  add_foreign_key "strength_sessions", "workout_plans"
  add_foreign_key "workout_plan_exercises", "workout_plans"
  add_foreign_key "workouts", "daily_logs"
end
