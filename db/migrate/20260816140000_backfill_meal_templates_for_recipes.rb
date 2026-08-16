# frozen_string_literal: true

# User-created recipes only showed under Recipes — Build a meal lists MealTemplates.
# Link every recipe that has tracked ingredients so hummus etc. can be logged.
class BackfillMealTemplatesForRecipes < ActiveRecord::Migration[8.0]
  def up
    Recipe.includes(:recipe_ingredients, :meal_template).find_each do |recipe|
      next if recipe.recipe_ingredients.none? { |i| i.product_id.present? && i.quantity_g.to_f.positive? }

      recipe.ensure_meal_template!
    end
  end

  def down
    # Keep templates — they may already be used by meal entries.
  end
end
