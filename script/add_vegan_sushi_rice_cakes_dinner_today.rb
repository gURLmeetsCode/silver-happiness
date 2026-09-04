# frozen_string_literal: true

# Tonight's dinner: vegan sushi roll + 4 rice cakes with sauces.
#
#   bin/rails runner script/add_vegan_sushi_rice_cakes_dinner_today.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_vegan_sushi_rice_cakes_dinner_today.rb

DATE = ENV.fetch("LOGGED_ON", Date.current.to_s).then { |value| Date.parse(value) }

# Estimates where the café/product label isn't in the app yet — edit via Products.
NEW_PRODUCTS = [
  {
    name: "Sushi rice (cooked)",
    brand: nil,
    calories_per_100g: 130,
    protein_per_100g: 2.4,
    carbs_per_100g: 28.0,
    fat_per_100g: 0.3,
    default_serving_g: 45,
    serving_label: "3 tbsp cooked (~45 g)",
    notes: "Estimate for seasoned cooked sushi rice (CIQUAL-style cooked white rice ~130 kcal/100 g). " \
           "Update if you weigh a batch."
  },
  {
    name: "Sauce soja sucrée",
    brand: nil,
    calories_per_100g: 270,
    protein_per_100g: 2.0,
    carbs_per_100g: 62.0,
    fat_per_100g: 0.1,
    default_serving_g: 5,
    serving_label: "1 tsp (~5 g)",
    notes: "Placeholder for sweet soy / ketjap-style. Typical ~250–280 kcal/100 g. " \
           "Update with your bottle's label in the app."
  }
].freeze

# tbsp ≈ 15 g for sauces; tsp ≈ 5 g. Strips ≈ julienne finger pieces.
ITEMS = [
  # Vegan sushi roll
  { product: "Tofu", grams: 45, note: "roll: 3–4 strips Céréal Bio" },
  { product: "Carrot", grams: 25, note: "roll: 3–4 strips" },
  { product: "Cucumber", grams: 30, note: "roll: 3–4 strips" },
  { product: "Sushi rice (cooked)", grams: 45, note: "roll: 3 tbsp" },
  # 4 rice cakes + same veg/tofu again as toppings
  { product: "Galettes de riz", grams: 40, note: "4 cakes × ~10 g" },
  { product: "Tofu", grams: 45, note: "cakes: 3–4 strips" },
  { product: "Carrot", grams: 25, note: "cakes: 3–4 strips" },
  { product: "Cucumber", grams: 30, note: "cakes: 3–4 strips" },
  # Sauces
  { product: "Sauce sriracha", grams: 30, note: "2 tbsp U" },
  { product: "Moutarde au miel", grams: 30, note: "2 tbsp Maille" },
  { product: "Marinade miso sucrée", grams: 15, note: "1 tbsp" },
  { product: "Sauce soja sucrée", grams: 5, note: "1 tsp" }
].freeze

MEAL_NAME = "Vegan sushi roll + 4 galettes de riz (sauces)"

puts "==> Ensuring new products"
NEW_PRODUCTS.each do |attrs|
  product = Product.find_or_initialize_by(name: attrs[:name])
  product.assign_attributes(attrs)
  product.save!
  puts "  #{product.name}"
end

# Fill missing defaults on sauces already in DB
sriracha = Product.find_by!(name: "Sauce sriracha")
if sriracha.default_serving_g.blank?
  sriracha.update!(default_serving_g: 15, serving_label: "1 tbsp (~15 g)")
end

puts "==> Building dinner for #{DATE}"
log = DailyLog.find_or_create_by!(logged_on: DATE)

rows = ITEMS.map do |item|
  product = Product.find_by!(name: item[:product])
  { "product_id" => product.id, "quantity" => item[:grams], "unit" => "g" }
end

entry = log.meal_entries.find_by(name: MEAL_NAME)
entry ||= log.meal_entries.build(meal_type: :dinner)
entry.name = MEAL_NAME
entry.meal_type = :dinner
MealAssembler.new(rows).apply!(entry, replace_notes: true)
entry.notes = [
  entry.notes,
  "1 hand roll: tofu/carrot/cucumber strips + 3 tbsp sushi rice. " \
  "4 Tien Shan rice cakes with same strips. Sauces: 2 tbsp U sriracha, " \
  "2 tbsp miel mustard, 1 tbsp miso marinade, 1 tsp sweet soy (placeholder — update label)."
].compact_blank.join(" · ")
entry.save!

action = entry.previously_new_record? ? "added" : "updated"
puts "  #{action}: #{entry.name}"
puts "  #{entry.calories} kcal · #{entry.protein_g} g protein · #{entry.carbs_g} g carbs · #{entry.fat_g} g fat"
entry.items.includes(:product).each do |i|
  n = i.product.nutrition_for(i.grams)
  puts "    #{i.grams.to_i} g #{i.product.name} → #{n[:calories]} kcal"
end

log.reload
puts "==> Day total: #{log.total_calories} kcal · #{log.total_protein.round(1)} g protein"
