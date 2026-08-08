# frozen_string_literal: true

require "test_helper"

class MealEntryNutritionBuilderTest < ActiveSupport::TestCase
  test "scales recipe base by servings and adds tbsp extras" do
    recipe = Recipe.find_by(slug: "chipotle-yogurt-salad") || build_chipotle_recipe
    log = DailyLog.create!(logged_on: Date.new(2026, 8, 8))
    entry = log.meal_entries.build(name: recipe.name, meal_type: :lunch, meal_template: recipe.meal_template)

    cholula = Product.find_or_create_by!(name: "Cholula Chipotle sauce") do |p|
      p.default_serving_g = 15
    end

    per = recipe.nutrition_per_serving
    MealEntryNutritionBuilder.new(
      entry,
      recipe: recipe,
      servings: 3,
      extras: {
        "0" => { product_id: cholula.id, quantity: 3, unit: "tbsp" }
      }
    ).apply!

    assert_equal (per[:calories] * 3).round, entry.calories
    assert_includes entry.notes, "Cholula"
  end

  private

  def build_chipotle_recipe
    template = MealTemplate.create!(name: "Wrap", slug: "test-wrap-#{SecureRandom.hex(4)}", meal_type: :lunch)
    wrap = Product.create!(name: "Test wrap #{SecureRandom.hex(2)}", calories_per_100g: 300, protein_per_100g: 8, default_serving_g: 32)
    Recipe.create!(
      name: "Test wrap",
      slug: "test-wrap-recipe-#{SecureRandom.hex(4)}",
      meal_type: :lunch,
      meal_template: template,
      serves: 1,
      recipe_ingredients_attributes: [
        { name: wrap.name, product_id: wrap.id, quantity_g: 32, position: 0, grocery_category: :carbs }
      ]
    )
  end
end
