# frozen_string_literal: true

# Re-sync brownie recipe ingredients after as-made update (remove leftover flax/chips).
class ResyncNoracooksBrowniesIngredients < ActiveRecord::Migration[8.0]
  def up
    recipe = Recipe.find_by(slug: "noracooks-oil-free-walnut-brownies")
    template = MealTemplate.find_by(slug: "noracooks-oil-free-walnut-brownies")
    return unless recipe && template
    return if recipe.user_created?

    recipe.recipe_ingredients.destroy_all
    recipe.sync_from_meal_template!
  end

  def down
    # no-op
  end
end
