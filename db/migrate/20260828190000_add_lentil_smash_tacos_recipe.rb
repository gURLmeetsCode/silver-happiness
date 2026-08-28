# frozen_string_literal: true

# Derek Sarno smash lentil tacos — adapted to French pantry products (no cheese).
# Source: youtube.com/watch?v=gmLQB_nL1aE ("The Best Lentils Dish Ever")
# Batch = 8 tacos (1 pack Old El Paso). Log servings = tacos you ate.
class AddLentilSmashTacosRecipe < ActiveRecord::Migration[8.0]
  PRODUCTS = [
    {
      name: "Old El Paso Tortillas Maïs et Blé",
      brand: "Old El Paso",
      calories_per_100g: 289,
      protein_per_100g: 8.5,
      carbs_per_100g: 51.8,
      fat_per_100g: 4.8,
      default_serving_g: 42,
      serving_label: "1 tortilla (~42 g)",
      notes: "Extra Moelleuses Maïs et Blé — pack of 8 / 335 g. ~121 kcal · 3.6 g protein per tortilla."
    },
    {
      name: "U Lentilles Blondes (dry)",
      brand: "U",
      barcode: "3256220659123",
      calories_per_100g: 347,
      protein_per_100g: 24.6,
      carbs_per_100g: 48.5,
      fat_per_100g: 1.4,
      default_serving_g: 200,
      serving_label: "1 cup dry (~200 g)",
      notes: "Dry blond lentils (CIQUAL-style). Cook ~20 min simmer / 12 min pressure cooker. " \
             "Log dry weight for recipes."
    },
    {
      name: "Panzani Tomacouli Nature",
      brand: "Panzani",
      barcode: "3038359006456",
      calories_per_100g: 37,
      protein_per_100g: 1.7,
      carbs_per_100g: 6.1,
      fat_per_100g: 0.2,
      default_serving_g: 100,
      serving_label: "100 g (~⅓ cup)",
      notes: "Purée de tomates sans sel ajouté. Label: 37 kcal / 100 g. 500 g carton."
    },
    {
      name: "Tortilla Nachips Original",
      brand: "Tortilla Nachips",
      calories_per_100g: 492,
      protein_per_100g: 6.5,
      carbs_per_100g: 60.0,
      fat_per_100g: 24.0,
      default_serving_g: 30,
      serving_label: "1 small handful (~30 g)",
      notes: "Corn tortilla chips, gluten-free. Label ~492 kcal / 100 g. Crush into smash-taco filling."
    },
    {
      name: "Onion",
      calories_per_100g: 39,
      protein_per_100g: 1.1,
      carbs_per_100g: 7.0,
      fat_per_100g: 0.1,
      default_serving_g: 150,
      serving_label: "1 medium (~150 g)",
      notes: "CIQUAL oignon cru. Also covers shallots when a recipe lists both."
    }
  ].freeze

  # Full batch ÷ 8 tacos (1 cup dry lentils, ~400 g Tomacouli, 1 onion + shallots,
  # 3 tbsp sauté oil + ~1 tsp fry oil per taco, handful chips, 8 tortillas). No cheese.
  PER_TACO = {
    "Old El Paso Tortillas Maïs et Blé" => 42,
    "U Lentilles Blondes (dry)" => 25,
    "Panzani Tomacouli Nature" => 50,
    "Onion" => 25,
    "Puget Huile d'olive vierge extra" => 9,
    "Tortilla Nachips Original" => 5
  }.freeze

  def up
    PRODUCTS.each do |attrs|
      product = Product.find_or_initialize_by(name: attrs[:name])
      product.assign_attributes(attrs)
      product.save!
    end

    oil = Product.find_by(name: "Puget Huile d'olive vierge extra") ||
      Product.create!(
        name: "Puget Huile d'olive vierge extra",
        brand: "Puget",
        calories_per_100g: 900, protein_per_100g: 0, carbs_per_100g: 0, fat_per_100g: 100,
        default_serving_g: 10, serving_label: "1 tbsp (10 g)"
      )

    template = MealTemplate.find_or_initialize_by(slug: "lentil-smash-tacos")
    template.assign_attributes(name: "Lentil smash tacos", meal_type: :dinner)
    template.save!
    template.meal_template_items.destroy_all

    PER_TACO.each do |name, grams|
      product = name == "Puget Huile d'olive vierge extra" ? oil : Product.find_by!(name: name)
      template.meal_template_items.create!(
        product: product,
        quantity_g: grams,
        label: "#{label_for(name, grams)}"
      )
    end

    recipe = Recipe.find_or_initialize_by(slug: "lentil-smash-tacos")
    return if recipe.persisted? && recipe.user_created?

    recipe.assign_attributes(
      name: "Lentil smash tacos",
      meal_type: :dinner,
      meal_template: template,
      regular_meal: true,
      serves: 1,
      position: 22,
      prep_time: "40 min",
      water_suggestion_ml: 300,
      description: "Derek Sarno smash lentil tacos (no cheese) with U blond lentils, " \
                   "Panzani Tomacouli, Tortilla Nachips, and Old El Paso Maïs et Blé tortillas. " \
                   "Batch = 8 tacos. Log servings = tacos you ate. " \
                   "Source: youtube.com/watch?v=gmLQB_nL1aE",
      personal_notes: "As made: no cheese. Tomacouli instead of plum tomatoes; Nachips crushed into filling; " \
                     "Maïs et Blé Extra Moelleuses (335 g / 8).",
      steps: <<~STEPS.strip
        Adapted from Derek Sarno — The Best Lentils Dish Ever (smash tacos). No cheese.

        Batch (8 tacos):
        1. Rinse 200 g (≈1 cup) U blond lentils. Dice 1 onion + 2 shallots; mince 4 garlic cloves.
        2. Warm a light coat of olive oil (~3 tbsp) in a saucepan; toast chili powder, cumin, salt, pepper (~1–2 min).
        3. Sauté onion, shallots, and garlic until soft. Add lentils + ~400 g Panzani Tomacouli Nature + ~2½ cups water.
        4. Boil, then simmer until lentils are soft (~20 min). Cool. For a thicker, oil-free-style mash, blend half and stir back in.
        5. Crush a good handful (~40 g) Tortilla Nachips into the cooled mix.
        6. Spread filling over half of each Old El Paso Maïs et Blé tortilla, fold, and pan-fry in a little oil until crisp on both sides.
        7. Top with shredded lettuce + quick pico (tomato, red onion, lime, coriander). No cheese.

        To log: Servings = smash tacos you ate (e.g. 2 or 3).
      STEPS
    )
    recipe.save!
    recipe.sync_from_meal_template!

    # Drop the wheat-only pack if an earlier local migrate created it.
    Product.find_by(name: "Old El Paso Tortillas Blé Nature")&.destroy
  end

  def down
    Recipe.find_by(slug: "lentil-smash-tacos")&.destroy
    MealTemplate.find_by(slug: "lentil-smash-tacos")&.destroy
  end

  private

  def label_for(name, grams)
    case name
    when "Old El Paso Tortillas Maïs et Blé" then "1 tortilla (~#{grams} g)"
    when "U Lentilles Blondes (dry)" then "#{grams} g dry lentils (1/8 batch)"
    when "Panzani Tomacouli Nature" then "#{grams} g Tomacouli (1/8 batch)"
    when "Onion" then "#{grams} g onion + shallot (1/8 batch)"
    when "Puget Huile d'olive vierge extra" then "#{grams} g oil (sauté + fry)"
    when "Tortilla Nachips Original" then "#{grams} g crushed Nachips (1/8 batch)"
    else "#{grams} g"
    end
  end
end
