# frozen_string_literal: true

require "rails_helper"

RSpec.describe MealEntryNutritionBuilder do
  let(:template) { create(:meal_template, meal_type: :lunch) }
  let(:wrap) { create(:product, calories_per_100g: 300, protein_per_100g: 8, default_serving_g: 32) }
  let(:recipe) do
    recipe = create(:recipe, meal_type: :lunch, meal_template: template, serves: 1)
    recipe.recipe_ingredients.create!(
      name: wrap.name, product: wrap, quantity_g: 32, position: 0, grocery_category: :carbs
    )
    recipe.reload
  end

  it "scales the recipe base by servings and adds tbsp extras" do
    log = create(:daily_log)
    entry = log.meal_entries.build(name: recipe.name, meal_type: :lunch, meal_template: template)
    sauce = create(:product, name: "Cholula Chipotle sauce", default_serving_g: 15)
    per = recipe.nutrition_per_serving

    described_class.new(
      entry,
      recipe: recipe,
      servings: 3,
      extras: { "0" => { product_id: sauce.id, quantity: 3, unit: "tbsp" } }
    ).apply!

    expect(entry.calories).to eq((per[:calories] * 3).round + sauce.nutrition_for(45)[:calories])
    expect(entry.notes).to include("Cholula")
  end

  it "treats servings below one as a single serving" do
    log = create(:daily_log)
    entry = log.meal_entries.build(name: recipe.name, meal_type: :lunch)

    described_class.new(entry, recipe: recipe, servings: 0).apply!

    expect(entry.calories).to eq(recipe.nutrition_per_serving[:calories].round)
  end

  it "ignores extras with a blank product" do
    log = create(:daily_log)
    entry = log.meal_entries.build(name: recipe.name, meal_type: :lunch)

    described_class.new(
      entry, recipe: recipe, servings: 1, extras: { "0" => { product_id: "", quantity: 3, unit: "g" } }
    ).apply!

    expect(entry.notes).to be_blank
  end

  it "adds gram extras directly" do
    log = create(:daily_log)
    entry = log.meal_entries.build(name: "Snack", meal_type: :snack, calories: 0, protein_g: 0)
    berries = create(:product, name: "Strawberries", calories_per_100g: 32, protein_per_100g: 0.7)

    described_class.new(
      entry, servings: 1, extras: { "0" => { product_id: berries.id, quantity: 50, unit: "g" } }
    ).apply!

    expect(entry.calories).to eq(16)
  end
end
