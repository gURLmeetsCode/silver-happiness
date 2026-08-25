# frozen_string_literal: true

# Additive breakfast log — Madeleine Café (Nantes), 2026-08-25.
#
# Menu (madeleine-cafe.fr): flap jack / farine sans gluten 3,50 · macchiato 3,50.
# Café publishes no nutrition labels — estimates from typical café flapjack bars
# (~90 g oat/syrup style) and a traditional espresso macchiato (espresso + milk mark).
#
#   bin/rails runner script/add_2026_08_25_madeleine_breakfast.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_2026_08_25_madeleine_breakfast.rb

DATE = Date.new(2026, 8, 25)

PRODUCTS = [
  {
    name: "Madeleine Café flapjack (GF)",
    brand: "Madeleine Café Nantes",
    calories_per_100g: 439,
    protein_per_100g: 5.9,
    carbs_per_100g: 54.0,
    fat_per_100g: 21.0,
    default_serving_g: 55,
    serving_label: "1 strip (~55 g, middle-finger length)",
    notes: "Estimate. Menu: flap jack / farine sans gluten (3,50 €). " \
           "Piece ~middle-finger length — ~55 g strip (not a 90 g giant bar). " \
           "Macros from typical oat flapjack ~439 kcal · 5.9 g protein / 100 g."
  },
  {
    name: "Madeleine Café macchiato (lait végétal)",
    brand: "Madeleine Café Nantes",
    beverage: true,
    calories_per_100g: 45.0,
    protein_per_100g: 1.0,
    carbs_per_100g: 6.0,
    fat_per_100g: 1.5,
    default_serving_g: 40,
    serving_label: "1 macchiato · oat milk (~40 ml)",
    notes: "Estimate. Espresso macchiato with lait végétal (menu: +0,50 lait d'avoine). " \
           "Espresso + small oat-milk mark — ~18 kcal (not cow’s milk, not a latte)."
  }
].freeze

MEAL = {
  name: "Madeleine Café — flapjack + macchiato (lait végétal)",
  meal_type: :breakfast,
  items: [
    { product: "Madeleine Café flapjack (GF)", quantity: 1, unit: "serving" },
    { product: "Madeleine Café macchiato (lait végétal)", quantity: 1, unit: "serving" }
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

entry = log.meal_entries.find_by(name: MEAL[:name])
entry ||= log.meal_entries.find_by(name: "Madeleine Café — flapjack + macchiato")
entry ||= log.meal_entries.build(meal_type: MEAL[:meal_type])

entry.name = MEAL[:name]
entry.meal_type = MEAL[:meal_type]
MealAssembler.new(rows).apply!(entry)
entry.notes = [
  "Madeleine Café Nantes estimates (no published labels). " \
  "Flapjack ~55 g middle-finger-length GF strip; macchiato = espresso + lait végétal (avoine) ~18 kcal."
].compact_blank.join(" · ")
entry.save!

action = entry.previously_new_record? ? "added" : "updated"
puts "  #{action}: #{entry.name} (#{entry.calories} kcal, #{entry.protein_g} g protein)"

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
