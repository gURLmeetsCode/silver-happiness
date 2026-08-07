class AddWaterSuggestionsToMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :water_suggestion_ml, :integer, default: 250, null: false
    add_column :meal_templates, :water_suggestion_ml, :integer, default: 250, null: false

    change_table :meal_entries, bulk: true do |t|
      t.integer :water_suggestion_ml, default: 250, null: false
      t.integer :water_logged_ml, default: 0, null: false
    end
  end
end
