# frozen_string_literal: true

# Additive cinema snack for 2026-08-14 — UGC Atlantis (Spider-Man VO).
# Medium salted popcorn + standard M&M's Peanut bag (45 g).
#
#   bin/rails runner script/add_2026_08_14_cinema_snack.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_2026_08_14_cinema_snack.rb

DATE = Date.new(2026, 8, 14)
MEAL_NAME = "Cinema snack — popcorn salé + M&M's cacahuète"

PRODUCTS = [
  {
    name: "Popcorn salé cinéma (moyen)",
    brand: "Pathé / UGC",
    calories_per_100g: 450,
    protein_per_100g: 7.0,
    carbs_per_100g: 55.0,
    fat_per_100g: 22.0,
    default_serving_g: 100,
    serving_label: "1 medium salted (~100 g)",
    notes: "Pathé/Jimmy’s-style salted medium (~100 g ≈ 450 kcal). Cinema estimate."
  },
  {
    name: "M&M's Peanut (cacahuète)",
    brand: "M&M's",
    calories_per_100g: 524,
    protein_per_100g: 9.8,
    carbs_per_100g: 59.0,
    fat_per_100g: 26.0,
    default_serving_g: 45,
    serving_label: "1 bag (~45 g)",
    notes: "Label: ~524 kcal/100 g. Standard 45 g bag ≈ 236 kcal."
  }
].freeze

MEAL = {
  name: MEAL_NAME,
  meal_type: :snack,
  items: [
    { product: "Popcorn salé cinéma (moyen)", quantity: 1, unit: "serving" },
    { product: "M&M's Peanut (cacahuète)", quantity: 1, unit: "serving" }
  ]
}.freeze

puts "==> Ensuring products exist"
PRODUCTS.each do |attrs|
  product = Product.find_or_initialize_by(name: attrs[:name])
  product.assign_attributes(attrs)
  product.save!
  puts "  product: #{product.name}"
end

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id}"

rows = MEAL[:items].map do |item|
  product = Product.find_by!(name: item[:product])
  { "product_id" => product.id, "quantity" => item[:quantity], "unit" => item[:unit] }
end

entry = log.meal_entries.find_or_initialize_by(name: MEAL[:name])
entry.meal_type = MEAL[:meal_type]
MealAssembler.new(rows).apply!(entry)
entry.notes = [
  entry.notes,
  "UGC Atlantis Spider-Man VO. Medium salted popcorn + 45 g M&M's Peanut."
].compact_blank.join(" · ")
entry.save!

action = entry.previously_new_record? ? "added" : "updated"
puts "  #{action}: #{entry.name} (#{entry.calories} kcal, #{entry.protein_g} g protein)"

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
