# frozen_string_literal: true

# Complete light dinner: 2 oven brochettes + big salad + small quinoa scoop.
# Log 1× = the full plate (not per skewer).
class AddOvenBrochettesPlateRecipe < ActiveRecord::Migration[8.0]
  # 2× brochette per-skewer + 90 g cooked quinoa (~½ cup) + 1 tbsp dressing + cucumber.
  PER_PLATE = {
    "Tofu" => 84,
    "Mushrooms (button)" => 80,
    "Red pepper" => 70,
    "Onion" => 50,
    "Zucchini" => 80,
    "Homemade BBQ bean brush" => 40,
    "Puget Huile d'olive vierge extra" => 6,
    "Cucumber" => 80,
    "Quinoa cuit" => 90,
    "Homemade salad dressing" => 15
  }.freeze

  LABELS = {
    "Tofu" => "84 g tofu (2 skewers / ~⅓ pack)",
    "Mushrooms (button)" => "~4 caps (~80 g)",
    "Red pepper" => "70 g pepper",
    "Onion" => "50 g onion",
    "Zucchini" => "80 g zucchini",
    "Homemade BBQ bean brush" => "~3 tbsp brush (2 skewers)",
    "Puget Huile d'olive vierge extra" => "light oil on skewers",
    "Cucumber" => "80 g cucumber on salad",
    "Quinoa cuit" => "90 g cooked quinoa (~½ cup)",
    "Homemade salad dressing" => "1 tbsp dressing"
  }.freeze

  def up
    missing = PER_PLATE.keys.reject { |name| Product.exists?(name: name) }
    raise "Missing products for brochettes plate: #{missing.join(', ')}" if missing.any?

    template = MealTemplate.find_or_initialize_by(slug: "oven-brochettes-plate")
    template.assign_attributes(
      name: "Oven brochettes plate (salad + quinoa)",
      meal_type: :dinner,
      water_suggestion_ml: 350
    )
    template.save!
    template.meal_template_items.destroy_all

    PER_PLATE.each do |product_name, grams|
      product = Product.find_by!(name: product_name)
      template.meal_template_items.create!(
        product: product,
        quantity_g: grams,
        label: LABELS[product_name] || "#{grams} g"
      )
    end

    recipe = Recipe.find_or_initialize_by(slug: "oven-brochettes-plate")
    return if recipe.persisted? && recipe.user_created?

    recipe.assign_attributes(
      name: "Oven brochettes plate (salad + quinoa)",
      meal_type: :dinner,
      meal_template: template,
      regular_meal: true,
      serves: 1,
      position: 25,
      prep_time: "45 min",
      water_suggestion_ml: 350,
      description: "Complete light dinner: 2 BBQ-bean oven brochettes + a big green salad + " \
                   "½ cup cooked quinoa. Volume without calorie density. Log 1× = the plate.",
      personal_notes: "Prefer this over plain skewers when you want a full meal. " \
                      "Keep quinoa to ~90 g cooked; greens are free volume.",
      steps: <<~STEPS.strip,
        1. Make / reheat 2 oven veggie brochettes (tofu, mushrooms, pepper, onion, zucchini;
           BBQ bean brush; bake 200°C ~20–25 min).
        2. Big salad: 2 big handfuls mâche/mesclun + cucumber, tomato, extra pepper if you want.
        3. Scoop 90 g cooked quinoa (~½ cup) beside the skewers — not a heaping bowl.
        4. Drizzle exactly 1 tbsp measured balsamic dressing on the salad.
        5. Log 1× for the full plate.
      STEPS
      status: :active
    )
    recipe.save!
    recipe.sync_from_meal_template!

    # Untracked greens for grocery / steps (macros come from template products).
    unless recipe.recipe_ingredients.exists?(name: "mâche / mesclun")
      max_pos = recipe.recipe_ingredients.maximum(:position).to_i
      recipe.recipe_ingredients.create!(
        grocery_category: :produce,
        amount: "2 big handfuls",
        name: "mâche / mesclun",
        position: max_pos + 1
      )
      recipe.recipe_ingredients.create!(
        grocery_category: :produce,
        amount: "handful",
        name: "cherry tomatoes (optional)",
        position: max_pos + 2
      )
    end
  end

  def down
    Recipe.find_by(slug: "oven-brochettes-plate")&.destroy
    MealTemplate.find_by(slug: "oven-brochettes-plate")&.destroy
  end
end
