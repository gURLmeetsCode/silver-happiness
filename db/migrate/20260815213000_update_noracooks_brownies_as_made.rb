# frozen_string_literal: true

# Update brownies to how Natasha actually made them:
# - chia seeds instead of flax
# - no chocolate chips
# - baked in 1/8-cup cupcake molds → 15 pieces
class UpdateNoracooksBrowniesAsMade < ActiveRecord::Migration[8.0]
  # Full batch ÷ 15 cupcakes.
  # Chia: 4 tbsp × 15 g (app serving) = 60 g.
  PER_CUPCAKE = {
    "Chia seeds" => 4.0,                 # 60 / 15
    "Unsweetened applesauce" => 8.133,   # 122 / 15
    "Granulated sugar" => 13.333,        # 200 / 15
    "Brown sugar" => 14.667,             # 220 / 15
    "All-purpose flour" => 8.333,        # 125 / 15
    "Unsweetened cocoa powder" => 5.733, # 86 / 15
    "Walnuts" => 5.0                     # 75 / 15 (¾ cup)
  }.freeze

  def up
    chia = Product.find_by(name: "Chia seeds") ||
      Product.create!(
        name: "Chia seeds",
        calories_per_100g: 486, protein_per_100g: 17, carbs_per_100g: 42, fat_per_100g: 31,
        default_serving_g: 15, serving_label: "1 tbsp"
      )

    flour = Product.find_by!(name: "All-purpose flour")

    template = MealTemplate.find_by(slug: "noracooks-oil-free-walnut-brownies")
    return unless template

    template.update!(
      name: "Nora Cooks oil-free walnut brownies (cupcakes)",
      meal_type: :snack
    )
    template.meal_template_items.destroy_all

    PER_CUPCAKE.each do |name, grams|
      product = case name
      when "All-purpose flour" then flour
      when "Chia seeds" then chia
      else Product.find_by!(name: name)
      end
      template.meal_template_items.create!(
        product: product,
        quantity_g: grams,
        label: "#{grams.round(2)} g (1 cupcake of 15)"
      )
    end

    recipe = Recipe.find_by(slug: "noracooks-oil-free-walnut-brownies")
    return unless recipe
    return if recipe.user_created?

    recipe.assign_attributes(
      name: "Nora Cooks oil-free walnut brownies (cupcakes)",
      meal_template: template,
      description: "Nora Cooks Best Ever Vegan Brownies, oil-free (applesauce for butter), " \
                   "chia instead of flax, walnuts, no chocolate chips. " \
                   "Baked as 15 cupcakes in ⅛-cup molds. Log servings = cupcakes eaten. " \
                   "Source: noracooks.com/vegan-brownies-recipe",
      personal_notes: "As made: chia eggs (not flax), no chocolate chips, ⅛-cup cupcake molds → 15.",
      steps: <<~STEPS.strip
        Nora Cooks oil-free brownies — as made (chia, no chips, cupcake molds).

        Batch (15 cupcakes, ⅛-cup molds):
        1. Chia eggs: 4 tbsp chia seeds + ½ cup water; thicken.
        2. Oven 175°C / 350°F. Line or grease ⅛-cup cupcake molds.
        3. Whisk ½ cup unsweetened applesauce with 1 cup sugar + 1 cup packed brown sugar.
           Add chia eggs + 1 tbsp vanilla.
        4. Sift in 1 cup flour + 1 cup unsweetened cocoa; add ½ tsp salt + 1 tsp baking powder.
           Stir until just combined.
        5. Fold in ¾ cup chopped walnuts only (no chocolate chips).
        6. Fill molds; bake until set (check earlier than a full pan — start around 18–25 min).
           Cool before removing.

        To log: Servings = cupcakes you ate (e.g. 3).
      STEPS
    )
    recipe.save!
    recipe.recipe_ingredients.destroy_all
    recipe.sync_from_meal_template!
  end

  def down
    # Previous migration can be re-run mentally; leave as-is on rollback.
  end
end
