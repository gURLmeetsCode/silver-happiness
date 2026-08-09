# frozen_string_literal: true

# Log your share of Nora Cooks pancakes (batch shared between two — count YOUR pancakes only).
# Usage: RAILS_ENV=production bin/rails runner script/log_nora_pancakes_dinner.rb
# Defaults to yesterday. Override: LOGGED_ON=2026-08-08 PANCAKES=7 SKYR_TBSP=3 STRAWBERRY_G=50

logged_on = ENV.fetch("LOGGED_ON") { Date.current - 1 day }.to_s
pancakes = ENV.fetch("PANCAKES", "7").to_i
skyr_tbsp = ENV.fetch("SKYR_TBSP", "3").to_d
strawberry_g = ENV.fetch("STRAWBERRY_G", "50").to_d

recipe = Recipe.find_by!(slug: "noracooks-vegan-pancakes")
log = DailyLog.for_date(Date.parse(logged_on))
skyr = Product.find_by!(name: "Skyr vegan")
berries = Product.find_by!(name: "Strawberries")

entry = log.meal_entries.build(
  meal_template: recipe.meal_template,
  name: "#{recipe.name} (#{pancakes} pancakes)",
  meal_type: :dinner
)

MealEntryNutritionBuilder.new(
  entry,
  recipe: recipe,
  servings: pancakes,
  extras: {
    "0" => { product_id: skyr.id, quantity: skyr_tbsp, unit: "tbsp" },
    "1" => { product_id: berries.id, quantity: strawberry_g, unit: "g" }
  }
).apply!

if entry.save
  puts "Logged on #{log.logged_on}: #{entry.name}"
  puts "  #{entry.calories} kcal · #{entry.protein_g}g protein · #{entry.carbs_g}g carbs · #{entry.fat_g}g fat"
  puts "  Notes: #{entry.notes}" if entry.notes.present?
else
  warn entry.errors.full_messages.to_sentence
  exit 1
end
