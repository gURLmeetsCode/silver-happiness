class CreateMealEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_entries do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.references :meal_template, foreign_key: true
      t.integer :meal_type, null: false, default: 0
      t.string :name, null: false
      t.integer :calories, default: 0, null: false
      t.decimal :protein_g, precision: 8, scale: 2, default: 0, null: false
      t.text :notes
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
