# frozen_string_literal: true

require "test_helper"

class NoracooksPancakesSeedTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  parallelize(workers: 1)

  test "noracooks vegan pancakes recipe seed is valid" do
    create_pancake_products!
    create_template!

    $RECIPES_SEED_HELPER_ONLY = true
    load Rails.root.join("db/seeds/recipes.rb")

    seed_recipe "noracooks-vegan-pancakes", {
      name: "Nora Cooks vegan pancakes",
      meal_type: :dinner,
      regular_meal: false,
      meal_template_slug: "noracooks-vegan-pancakes",
      prep_time: "10 min",
      serves: 1,
      position: 13,
      water_suggestion_ml: 250,
      description: "Nora Cooks base batch — we make the smallest amount and split between two.",
      personal_notes: "Smallest batch shared with husband."
    }, [
      [ :carbs, "23.5 g", "all-purpose flour (per pancake)", "All-purpose flour", 23.5 ],
      [ :pantry, "30 ml", "soy milk (per pancake)", "Soja sans sucre", 30 ],
      [ :pantry, "19 ml", "water (per pancake)", nil, nil ],
      [ :fats, "3.5 g", "oil in batter (per pancake)", "Puget Huile d'olive vierge extra", 3.5 ],
      [ :pantry, "⅛ tsp", "baking powder, pinch salt, ~3 g sugar (per pancake)", nil, nil ],
      [ :protein, "optional", "Sojasun Skyr topping (add in extras when logging)", nil, nil ],
      [ :produce, "several small", "strawberries (add in extras when logging)", nil, nil ]
    ], "Whisk, cook, log servings."

    recipe = Recipe.find_by!(slug: "noracooks-vegan-pancakes")
    assert recipe.recipe_ingredients.all?(&:valid?), recipe.recipe_ingredients.reject(&:valid?).map { |i|
      "#{i.name}: #{i.errors.full_messages.to_sentence}"
    }.join("; ")
    assert recipe.nutrition_per_serving[:calories].positive?

    builder = RecipeMealFormBuilder.new(recipe)
    names = builder.suggested_products.map(&:name)
    assert_includes names, "Skyr vegan"
    assert_includes names, "Strawberries"
  ensure
    $RECIPES_SEED_HELPER_ONLY = false
  end

  test "seed_recipe does not link product when quantity_g is blank" do
    Product.create!(name: "Skyr vegan", calories_per_100g: 60, protein_per_100g: 7)

    $RECIPES_SEED_HELPER_ONLY = true
    load Rails.root.join("db/seeds/recipes.rb")

    recipe = Recipe.create!(name: "Test", slug: "test-recipe", meal_type: :dinner)
    seed_recipe "test-recipe", { name: "Test", meal_type: :dinner }, [
      [ :protein, "optional", "Skyr topping", "Skyr vegan", nil ]
    ], nil

    ingredient = recipe.recipe_ingredients.sole
    assert_nil ingredient.product_id
    assert ingredient.valid?
  ensure
    $RECIPES_SEED_HELPER_ONLY = false
  end

  private

  def create_pancake_products!
    Product.find_or_create_by!(name: "All-purpose flour") do |p|
      p.calories_per_100g = 364
      p.protein_per_100g = 10
      p.carbs_per_100g = 76
      p.fat_per_100g = 1
    end
    Product.find_or_create_by!(name: "Soja sans sucre") do |p|
      p.calories_per_100g = 43
      p.protein_per_100g = 3.9
    end
    Product.find_or_create_by!(name: "Puget Huile d'olive vierge extra") do |p|
      p.calories_per_100g = 900
      p.protein_per_100g = 0
      p.fat_per_100g = 100
    end
    Product.find_or_create_by!(name: "Skyr vegan") do |p|
      p.calories_per_100g = 60
      p.protein_per_100g = 7
      p.default_serving_g = 15
    end
    Product.find_or_create_by!(name: "Strawberries") do |p|
      p.calories_per_100g = 32
      p.protein_per_100g = 0.7
    end
  end

  def create_template!
    flour = Product.find_by!(name: "All-purpose flour")
    soja = Product.find_by!(name: "Soja sans sucre")
    oil = Product.find_by!(name: "Puget Huile d'olive vierge extra")

    template = MealTemplate.find_or_create_by!(slug: "noracooks-vegan-pancakes") do |t|
      t.name = "Nora Cooks vegan pancakes"
      t.meal_type = :dinner
    end
    template.meal_template_items.destroy_all
    template.meal_template_items.create!(product: flour, quantity_g: 23.5, label: "1 pancake batter")
    template.meal_template_items.create!(product: soja, quantity_g: 30, label: "soy milk")
    template.meal_template_items.create!(product: oil, quantity_g: 3.5, label: "oil")
  end
end
