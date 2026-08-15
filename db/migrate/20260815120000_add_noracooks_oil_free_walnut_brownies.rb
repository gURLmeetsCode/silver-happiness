# frozen_string_literal: true

# Nora Cooks Best Ever Vegan Brownies — oil-free (applesauce for butter) + walnuts.
# Source: https://www.noracooks.com/vegan-brownies-recipe/
# Batch = 16 brownies. Log servings = how many brownies you ate (e.g. 5).
class AddNoracooksOilFreeWalnutBrownies < ActiveRecord::Migration[8.0]
  PRODUCTS = [
    {
      name: "Ground flaxseed",
      calories_per_100g: 534, protein_per_100g: 18.3, carbs_per_100g: 28.9, fat_per_100g: 42.2,
      default_serving_g: 7, serving_label: "1 tbsp (~7 g)"
    },
    {
      name: "Unsweetened applesauce",
      calories_per_100g: 43, protein_per_100g: 0.2, carbs_per_100g: 11.3, fat_per_100g: 0.1,
      default_serving_g: 122, serving_label: "½ cup (~122 g)"
    },
    {
      name: "Granulated sugar",
      calories_per_100g: 387, protein_per_100g: 0, carbs_per_100g: 100, fat_per_100g: 0,
      default_serving_g: 200, serving_label: "1 cup (~200 g)"
    },
    {
      name: "Brown sugar",
      calories_per_100g: 380, protein_per_100g: 0, carbs_per_100g: 98, fat_per_100g: 0,
      default_serving_g: 220, serving_label: "1 cup packed (~220 g)"
    },
    {
      name: "Unsweetened cocoa powder",
      calories_per_100g: 228, protein_per_100g: 19.6, carbs_per_100g: 57.9, fat_per_100g: 13.7,
      default_serving_g: 86, serving_label: "1 cup (~86 g)"
    },
    {
      name: "Dark chocolate chips (vegan)",
      calories_per_100g: 500, protein_per_100g: 5.0, carbs_per_100g: 60.0, fat_per_100g: 28.0,
      default_serving_g: 168, serving_label: "1 cup (~168 g)",
      notes: "Semi-sweet / dark dairy-free chips. ~500 kcal/100 g."
    },
    {
      name: "Walnuts",
      calories_per_100g: 654, protein_per_100g: 15.2, carbs_per_100g: 13.7, fat_per_100g: 65.2,
      default_serving_g: 30, serving_label: "¼ cup chopped (~30 g)"
    }
  ].freeze

  # Full batch grams ÷ 16 brownies (Nora oil-free swap + ¾ cup walnuts).
  PER_BROWNIE = {
    "Ground flaxseed" => 1.75,           # 28 g / 16
    "Unsweetened applesauce" => 7.625,   # 122 g / 16
    "Granulated sugar" => 12.5,          # 200 g / 16
    "Brown sugar" => 13.75,              # 220 g / 16
    "All-purpose flour" => 7.8125,       # 125 g / 16
    "Unsweetened cocoa powder" => 5.375, # 86 g / 16
    "Dark chocolate chips (vegan)" => 10.5, # 168 g / 16
    "Walnuts" => 4.6875                  # 75 g (¾ cup) / 16
  }.freeze

  def up
    PRODUCTS.each do |attrs|
      product = Product.find_or_initialize_by(name: attrs[:name])
      product.assign_attributes(attrs)
      product.save!
    end

    flour = Product.find_by(name: "All-purpose flour") ||
      Product.create!(
        name: "All-purpose flour",
        calories_per_100g: 364, protein_per_100g: 10, carbs_per_100g: 76, fat_per_100g: 1,
        default_serving_g: 125, serving_label: "1 cup (~125 g)"
      )

    template = MealTemplate.find_or_initialize_by(slug: "noracooks-oil-free-walnut-brownies")
    template.assign_attributes(
      name: "Nora Cooks oil-free walnut brownies",
      meal_type: :snack
    )
    template.save!
    template.meal_template_items.destroy_all

    PER_BROWNIE.each do |name, grams|
      product = name == "All-purpose flour" ? flour : Product.find_by!(name: name)
      template.meal_template_items.create!(
        product: product,
        quantity_g: grams,
        label: "#{grams.round(2)} g (1 brownie share of batch)"
      )
    end

    recipe = Recipe.find_or_initialize_by(slug: "noracooks-oil-free-walnut-brownies")
    return if recipe.persisted? && recipe.user_created?

    recipe.assign_attributes(
      name: "Nora Cooks oil-free walnut brownies",
      meal_type: :snack,
      meal_template: template,
      regular_meal: false,
      serves: 1,
      prep_time: "55 min",
      water_suggestion_ml: 250,
      description: "Nora Cooks Best Ever Vegan Brownies, oil-free (applesauce for butter) + ¾ cup walnuts. " \
                   "Batch = 16. Log servings = brownies you ate (e.g. 5). " \
                   "Source: noracooks.com/vegan-brownies-recipe",
      steps: <<~STEPS.strip,
        From Nora Cooks (noracooks.com/vegan-brownies-recipe) — oil-free + walnuts.

        Batch (16 brownies):
        1. Flax eggs: 4 tbsp ground flax + ½ cup water; thicken.
        2. Oven 175°C / 350°F. Line 7×11" (or 20×28 cm) pan with parchment.
        3. Whisk ½ cup unsweetened applesauce (oil-free swap for vegan butter) with 1 cup sugar + 1 cup packed brown sugar. Add flax eggs + 1 tbsp vanilla.
        4. Sift in 1 cup flour + 1 cup unsweetened cocoa; add ½ tsp salt + 1 tsp baking powder. Stir until just combined.
        5. Fold in half of 1 cup vegan chocolate chips + ¾ cup chopped walnuts. Spread in pan; top with remaining chips.
        6. Bake 35–40 min (will look soft; they firm as they cool). Cool before cutting into 16.

        To log: Servings = brownies you ate (e.g. 5).
      STEPS
      personal_notes: "Oil-free swap per Nora’s note (applesauce for butter). Walnuts ~¾ cup chopped in the batch."
    )
    recipe.save!
    recipe.sync_from_meal_template!
  end

  def down
    Recipe.find_by(slug: "noracooks-oil-free-walnut-brownies")&.destroy
    MealTemplate.find_by(slug: "noracooks-oil-free-walnut-brownies")&.destroy
  end
end
