class CreateGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :goals do |t|
      t.decimal :target_weight_kg, precision: 8, scale: 2, null: false, default: 56.0
      t.decimal :starting_weight_kg, precision: 8, scale: 2
      t.integer :protein_min_g, null: false, default: 90
      t.integer :protein_max_g, null: false, default: 100
      t.integer :calories_training_day, null: false, default: 1700
      t.integer :calories_rest_day, null: false, default: 1600
      t.date :target_date

      t.timestamps
    end
  end
end
