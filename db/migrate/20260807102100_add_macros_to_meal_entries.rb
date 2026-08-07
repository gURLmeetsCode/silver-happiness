class AddMacrosToMealEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :meal_entries, :carbs_g, :decimal, precision: 8, scale: 2, default: 0, null: false
    add_column :meal_entries, :fat_g, :decimal, precision: 8, scale: 2, default: 0, null: false
  end
end
