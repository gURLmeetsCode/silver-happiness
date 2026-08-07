class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.integer :activity_type, null: false, default: 0
      t.decimal :distance_km, precision: 8, scale: 2
      t.integer :calories_burned, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
