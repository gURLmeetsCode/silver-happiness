# frozen_string_literal: true

require "rails_helper"

RSpec.describe "db/seeds/recipes.rb" do
  # The seed file defines seed_recipe then runs every recipe. Loading it with
  # this flag set gives us the helper without the full seed run.
  def load_seed_helper!
    $RECIPES_SEED_HELPER_ONLY = true
    load Rails.root.join("db/seeds/recipes.rb")
  end

  after { $RECIPES_SEED_HELPER_ONLY = false }

  describe "seed_recipe" do
    it "does not link a product when quantity_g is blank" do
      create(:product, name: "Skyr vegan")
      load_seed_helper!
      recipe = create(:recipe, slug: "test-recipe")

      seed_recipe "test-recipe", { name: "Test", meal_type: :dinner }, [
        [ :protein, "optional", "Skyr topping", "Skyr vegan", nil ]
      ], nil

      ingredient = recipe.recipe_ingredients.sole
      expect(ingredient.product_id).to be_nil
      expect(ingredient).to be_valid
    end

    it "links a product when a positive quantity_g is given" do
      product = create(:product, name: "Tofu")
      load_seed_helper!
      recipe = create(:recipe, slug: "tofu-recipe")

      seed_recipe "tofu-recipe", { name: "Tofu", meal_type: :dinner }, [
        [ :protein, "150 g", "tofu", "Tofu", 150 ]
      ], nil

      expect(recipe.recipe_ingredients.sole.product).to eq(product)
    end
  end

  describe "the Nora Cooks pancakes recipe" do
    before do
      create(:product, name: "All-purpose flour", calories_per_100g: 364, protein_per_100g: 10, carbs_per_100g: 76, fat_per_100g: 1)
      create(:product, name: "Soja sans sucre", calories_per_100g: 43, protein_per_100g: 3.9)
      create(:product, name: "Puget Huile d'olive vierge extra", calories_per_100g: 900, protein_per_100g: 0, fat_per_100g: 100)
      create(:product, name: "Skyr vegan", calories_per_100g: 60, protein_per_100g: 7, default_serving_g: 15)
      create(:product, name: "Strawberries", calories_per_100g: 32, protein_per_100g: 0.7)

      template = create(:meal_template, name: "Nora Cooks vegan pancakes", slug: "noracooks-vegan-pancakes", meal_type: :dinner)
      template.meal_template_items.create!(product: Product.find_by!(name: "All-purpose flour"), quantity_g: 23.5, label: "1 pancake batter")
      template.meal_template_items.create!(product: Product.find_by!(name: "Soja sans sucre"), quantity_g: 30, label: "soy milk")
      template.meal_template_items.create!(product: Product.find_by!(name: "Puget Huile d'olive vierge extra"), quantity_g: 3.5, label: "oil")
    end

    it "seeds with every ingredient valid" do
      load_seed_helper!

      seed_recipe "noracooks-vegan-pancakes", {
        name: "Nora Cooks vegan pancakes",
        meal_type: :dinner,
        regular_meal: false,
        meal_template_slug: "noracooks-vegan-pancakes",
        serves: 1,
        water_suggestion_ml: 250,
        description: "Log your share."
      }, [
        [ :carbs, "23.5 g", "all-purpose flour (per pancake)", "All-purpose flour", 23.5 ],
        [ :pantry, "30 ml", "soy milk (per pancake)", "Soja sans sucre", 30 ],
        [ :pantry, "19 ml", "water (per pancake)", nil, nil ],
        [ :fats, "3.5 g", "oil in batter (per pancake)", "Puget Huile d'olive vierge extra", 3.5 ],
        [ :protein, "optional", "Sojasun Skyr topping (add in extras when logging)", nil, nil ],
        [ :produce, "several small", "strawberries (add in extras when logging)", nil, nil ]
      ], "Whisk, cook, log servings."

      recipe = Recipe.find_by!(slug: "noracooks-vegan-pancakes")
      invalid = recipe.recipe_ingredients.reject(&:valid?)

      expect(invalid).to be_empty, invalid.map { |i| "#{i.name}: #{i.errors.full_messages.to_sentence}" }.join("; ")
      expect(recipe.nutrition_per_serving[:calories]).to be_positive
    end

    it "offers skyr and strawberries as logging extras" do
      recipe = create(:recipe, slug: "noracooks-vegan-pancakes")

      names = RecipeMealFormBuilder.new(recipe).suggested_products.map(&:name)

      expect(names).to include("Skyr vegan", "Strawberries")
    end
  end

  describe "the lentil smash tacos recipe" do
    before do
      {
        "Old El Paso Tortillas Maïs et Blé" => { calories_per_100g: 289, protein_per_100g: 8.5, carbs_per_100g: 51.8, fat_per_100g: 4.8 },
        "U Lentilles Blondes (dry)" => { calories_per_100g: 347, protein_per_100g: 24.6, carbs_per_100g: 48.5, fat_per_100g: 1.4 },
        "Panzani Tomacouli Nature" => { calories_per_100g: 37, protein_per_100g: 1.7, carbs_per_100g: 6.1, fat_per_100g: 0.2 },
        "Onion" => { calories_per_100g: 39, protein_per_100g: 1.1, carbs_per_100g: 7.0, fat_per_100g: 0.1 },
        "Puget Huile d'olive vierge extra" => { calories_per_100g: 900, protein_per_100g: 0, carbs_per_100g: 0, fat_per_100g: 100 },
        "Tortilla Nachips Original" => { calories_per_100g: 492, protein_per_100g: 6.5, carbs_per_100g: 60.0, fat_per_100g: 24.0 }
      }.each do |name, macros|
        create(:product, { name: name }.merge(macros))
      end

      template = create(:meal_template, name: "Lentil smash tacos", slug: "lentil-smash-tacos", meal_type: :dinner)
      [
        [ "Old El Paso Tortillas Maïs et Blé", 42 ],
        [ "U Lentilles Blondes (dry)", 25 ],
        [ "Panzani Tomacouli Nature", 50 ],
        [ "Onion", 25 ],
        [ "Puget Huile d'olive vierge extra", 9 ],
        [ "Tortilla Nachips Original", 5 ]
      ].each do |name, grams|
        template.meal_template_items.create!(product: Product.find_by!(name: name), quantity_g: grams, label: name)
      end
    end

    it "seeds as a no-cheese smash taco with tracked pantry products" do
      load_seed_helper!

      seed_recipe "lentil-smash-tacos", {
        name: "Lentil smash tacos",
        meal_type: :dinner,
        regular_meal: true,
        meal_template_slug: "lentil-smash-tacos",
        serves: 1,
        description: "No cheese smash tacos."
      }, [
        [ :carbs, "1", "tortilla", "Old El Paso Tortillas Maïs et Blé", 42 ],
        [ :protein, "25 g", "lentils", "U Lentilles Blondes (dry)", 25 ],
        [ :produce, "50 g", "Tomacouli", "Panzani Tomacouli Nature", 50 ],
        [ :produce, "25 g", "onion", "Onion", 25 ],
        [ :pantry, "spices", "chili cumin", nil, nil ],
        [ :fats, "9 g", "oil", "Puget Huile d'olive vierge extra", 9 ],
        [ :carbs, "5 g", "Nachips", "Tortilla Nachips Original", 5 ],
        [ :produce, "toppings", "lettuce pico", nil, nil ]
      ], "Cook, smash, fry. No cheese."

      recipe = Recipe.find_by!(slug: "lentil-smash-tacos")
      expect(recipe.recipe_ingredients.reject(&:valid?)).to be_empty
      expect(recipe.nutrition_per_serving[:calories]).to be_between(300, 400)
      expect(recipe.steps).to match(/no cheese/i)
      expect(recipe.recipe_ingredients.map(&:name).join(" ")).not_to match(/cheese/i)
    end
  end
end
