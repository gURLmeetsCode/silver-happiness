# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adjusting a recipe meal's ingredients", type: :request do
  let(:daily_log) { DailyLog.today }

  # 200 g tofu at 150 kcal/100 g and 90 g avocado at 200 kcal/100 g.
  let(:tofu) { create(:product, name: "Tofu", calories_per_100g: 150, protein_per_100g: 15, carbs_per_100g: 3, fat_per_100g: 8) }
  let(:avocado) { create(:product, name: "Avocado", calories_per_100g: 200, protein_per_100g: 2, carbs_per_100g: 9, fat_per_100g: 20) }

  let(:recipe) do
    recipe = create(:recipe, :with_template, name: "Chipotle tofu wrap", serves: 1)
    recipe.recipe_ingredients.create!(name: "Tofu", product: tofu, quantity_g: 200, grocery_category: :protein)
    recipe.recipe_ingredients.create!(name: "Avocado", product: avocado, quantity_g: 90, grocery_category: :produce)
    recipe.recipe_ingredients.create!(name: "coriander", grocery_category: :produce)
    recipe.reload
  end

  let(:template) { recipe.meal_template }
  let(:tofu_ingredient) { recipe.recipe_ingredients.find_by(name: "Tofu") }
  let(:avocado_ingredient) { recipe.recipe_ingredients.find_by(name: "Avocado") }

  def log_meal(ingredients:)
    post daily_log_meal_entries_path(daily_log),
      params: { meal_template_id: template.id, ingredients: ingredients, meal_entry: { name: recipe.name } }
  end

  it "logs the recipe as written when nothing is adjusted" do
    log_meal(ingredients: {})

    entry = daily_log.meal_entries.last
    # 200 g tofu = 300 kcal, 90 g avocado = 180 kcal
    expect(entry.calories).to eq(480)
  end

  it "recalculates when an ingredient amount is changed" do
    log_meal(ingredients: { tofu_ingredient.id.to_s => { grams: "300", include: "1" } })

    entry = daily_log.meal_entries.last
    # 300 g tofu = 450 kcal, 90 g avocado = 180 kcal
    expect(entry.calories).to eq(630)
    expect(entry.protein_g).to eq(46.8)
  end

  it "drops an ingredient that was left out" do
    log_meal(ingredients: { avocado_ingredient.id.to_s => { grams: "90", include: "0" } })

    entry = daily_log.meal_entries.last
    expect(entry.calories).to eq(300)
  end

  it "remembers the adjustment so reopening the meal shows what was eaten" do
    log_meal(ingredients: {
      tofu_ingredient.id.to_s => { grams: "300", include: "1" },
      avocado_ingredient.id.to_s => { grams: "90", include: "0" }
    })

    entry = daily_log.meal_entries.last

    expect(entry.override_for(tofu_ingredient)).to eq(300)
    expect(entry.override_for(avocado_ingredient)).to eq(0)

    get edit_daily_log_meal_entry_path(daily_log, entry)

    expect(response.body).to include('value="300"')
    expect(response.body).to include("Avocado")
  end

  it "shows every product-linked ingredient as adjustable when logging" do
    get recipe_path(recipe)

    expect(response.body).to include("ingredients[#{tofu_ingredient.id}][grams]")
    expect(response.body).to include("ingredients[#{avocado_ingredient.id}][grams]")
  end

  it "lists ingredients with no product as untracked rather than adjustable" do
    get recipe_path(recipe)

    coriander = recipe.recipe_ingredients.find_by(name: "coriander")

    expect(response.body).not_to include("ingredients[#{coriander.id}][grams]")
    expect(response.body).to include("no calories tracked")
  end

  it "still applies extras on top of adjusted ingredients" do
    sauce = create(:product, name: "Cholula", calories_per_100g: 100, protein_per_100g: 0, carbs_per_100g: 20, fat_per_100g: 0, default_serving_g: 15)

    post daily_log_meal_entries_path(daily_log), params: {
      meal_template_id: template.id,
      meal_entry: { name: recipe.name },
      ingredients: { avocado_ingredient.id.to_s => { grams: "90", include: "0" } },
      extras: { "0" => { product_id: sauce.id, quantity: "2", unit: "tbsp" } }
    }

    entry = daily_log.meal_entries.last
    # 300 kcal tofu only, plus 30 g of sauce at 100 kcal/100 g
    expect(entry.calories).to eq(330)
    expect(entry.notes).to include("Cholula")
  end
end
