# frozen_string_literal: true

# Replace the rough "muffin + feta" estimate with macros from Natasha's
# hybrid vegan cake salé (tofu, pepper, onion, olives, vegan cheese).
# No sun-dried tomatoes in the batch she baked.
class UpdateSavouryMuffinFromRecipe < ActiveRecord::Migration[8.0]
  OLD_NAMES = [
    "Vegan cake-sale muffin with vegan feta",
    "Vegan tofu pepper olive savoury muffin"
  ].freeze
  NEW_NAME = "Cake salé"

  ATTRS = {
    name: NEW_NAME,
    brand: nil,
    calories_per_100g: 176,
    protein_per_100g: 6.0,
    carbs_per_100g: 18.1,
    fat_per_100g: 9.1,
    default_serving_g: 85,
    serving_label: "1 cake salé (~85 g)",
    notes: "Muffin-mold cake salé (batch of 12): flour, soy yogurt, soy milk, olive oil, " \
           "smoked tofu, green pepper, onion, olives, vegan cheese. No sun-dried tomatoes. " \
           "~150 kcal each. Estimated from recipe, not a label."
  }.freeze

  OLD_MEAL_NAMES = [
    "Vegan cake-sale muffin + feta",
    "Savoury tofu pepper olive muffin"
  ].freeze
  NEW_MEAL_NAME = "Cake salé"

  def up
    product = OLD_NAMES.filter_map { |n| Product.find_by(name: n) }.first
    product ||= Product.find_or_initialize_by(name: NEW_NAME)
    product.assign_attributes(ATTRS)
    product.save!

    MealEntry.where(name: OLD_MEAL_NAMES).find_each do |entry|
      entry.update!(name: NEW_MEAL_NAME)
    end

    MealEntryItem.where(product_id: product.id).find_each do |item|
      # One portion was logged at 125 g under the old estimate; recipe portion is ~85 g.
      item.update!(grams: 85) if item.grams.to_f >= 120
      recalculate_meal!(item.meal_entry)
    end
  end

  def down
    product = Product.find_by(name: NEW_NAME)
    return unless product

    product.update!(
      name: "Vegan cake-sale muffin with vegan feta",
      calories_per_100g: 280,
      protein_per_100g: 6,
      carbs_per_100g: 32,
      fat_per_100g: 14,
      default_serving_g: 125,
      serving_label: "1 muffin + feta (~125 g)",
      notes: "Estimate for a cake-sale vegan muffin topped with vegan feta (~350 kcal). " \
             "No label — rough only."
    )

    MealEntry.where(name: NEW_MEAL_NAME).find_each do |entry|
      entry.update!(name: "Vegan cake-sale muffin + feta")
    end
  end

  private

  def recalculate_meal!(entry)
    totals = entry.items.includes(:product).each_with_object(
      { calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0 }
    ) do |item, sum|
      n = item.product.nutrition_for(item.grams)
      sum[:calories] += n[:calories]
      sum[:protein] += n[:protein]
      sum[:carbs] += n[:carbs]
      sum[:fat] += n[:fat]
    end

    entry.update!(
      calories: totals[:calories].round,
      protein_g: totals[:protein].round(1),
      carbs_g: totals[:carbs].round(1),
      fat_g: totals[:fat].round(1)
    )
  end
end
