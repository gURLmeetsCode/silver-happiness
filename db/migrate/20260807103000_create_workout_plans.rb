class CreateWorkoutPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_plans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :location, null: false, default: 0
      t.integer :scheduled_wday
      t.text :description
      t.string :duration_hint

      t.timestamps
    end

    add_index :workout_plans, :slug, unique: true

    create_table :workout_plan_exercises do |t|
      t.references :workout_plan, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sets_prescription
      t.string :reps_prescription
      t.string :equipment_hint
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    create_table :strength_sessions do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.references :workout_plan, foreign_key: true
      t.integer :location, null: false, default: 0
      t.integer :perceived_difficulty
      t.text :notes
      t.integer :duration_min

      t.timestamps
    end

    create_table :strength_exercise_logs do |t|
      t.references :strength_session, null: false, foreign_key: true
      t.string :name, null: false
      t.string :equipment
      t.decimal :weight_kg, precision: 8, scale: 2
      t.integer :sets
      t.string :reps
      t.text :notes
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
