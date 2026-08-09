class AddIngredientOverridesToMealEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :meal_entries, :ingredient_overrides, :text
  end
end
