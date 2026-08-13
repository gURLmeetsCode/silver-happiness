# frozen_string_literal: true

# Additive lunch log for 2026-08-13 — L'Éthiquête (Nantes) + iced Americano.
# Estimates: restaurant publishes no labels; bowl macros from current "Pasta bowl"
# menu (chickpea pasta, veg, vinaigrette, tofu rosso). Fondant = typical vegan
# chocolate fondant portion. Americano = 35 ml espresso + water/ice, black.
#
#   bin/rails runner script/add_2026_08_13_ethiquete_lunch.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_2026_08_13_ethiquete_lunch.rb

DATE = Date.new(2026, 8, 13)

PRODUCTS = [
  {
    name: "Iced Americano (35 ml espresso)",
    brand: nil,
    beverage: true,
    calories_per_100g: 14,
    protein_per_100g: 0.9,
    carbs_per_100g: 2.0,
    fat_per_100g: 0.6,
    default_serving_g: 35,
    serving_label: "35 ml espresso + water/ice",
    notes: "Black iced Americano. ~5 kcal for a 35 ml espresso shot (CIQUAL/USDA-style). " \
           "Water and ice add nothing. No milk/syrup."
  },
  {
    name: "L'Éthiquête bowl du moment (pasta)",
    brand: "L'Éthiquête Nantes",
    calories_per_100g: 170,
    protein_per_100g: 8.0,
    carbs_per_100g: 18.0,
    fat_per_100g: 6.4,
    default_serving_g: 500,
    serving_label: "1 bowl (~500 g)",
    notes: "Estimate — no published nutrition. Menu (pasta bowl): chickpea pasta (GF), " \
           "cucumber, cherry tomato, pickles, corn, red beans, cabbage, carrot, beet, " \
           "greens, grilled pepper, sesame & squash seeds, vinaigrette, tofu rosso. " \
           "~850 kcal / ~40 g protein per bowl."
  },
  {
    name: "L'Éthiquête fondant au chocolat",
    brand: "L'Éthiquête Nantes",
    calories_per_100g: 370,
    protein_per_100g: 5.0,
    carbs_per_100g: 42.0,
    fat_per_100g: 20.0,
    default_serving_g: 100,
    serving_label: "1 portion (~100 g)",
    notes: "Estimate for restaurant vegan chocolate fondant / moelleux. " \
           "No label on site — ~370 kcal per portion."
  }
].freeze

MEAL = {
  name: "L'Éthiquête lunch — bowl + fondant + iced Americano",
  meal_type: :lunch,
  items: [
    { product: "Iced Americano (35 ml espresso)", quantity: 1, unit: "serving" },
    { product: "L'Éthiquête bowl du moment (pasta)", quantity: 1, unit: "serving" },
    { product: "L'Éthiquête fondant au chocolat", quantity: 1, unit: "serving" }
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

if log.meal_entries.exists?(name: MEAL[:name])
  puts "  skip (already present): #{MEAL[:name]}"
else
  rows = MEAL[:items].map do |item|
    product = Product.find_by!(name: item[:product])
    { "product_id" => product.id, "quantity" => item[:quantity], "unit" => item[:unit] }
  end

  entry = log.meal_entries.build(name: MEAL[:name], meal_type: MEAL[:meal_type])
  MealAssembler.new(rows).apply!(entry)
  entry.notes = [
    entry.notes,
    "Restaurant estimates (L'Éthiquête). Bowl composition changes — adjust if yours differed."
  ].compact_blank.join(" · ")
  entry.save!
  puts "  added: #{entry.name} (#{entry.calories} kcal, #{entry.protein_g} g protein)"
end

log.reload
puts "==> Done. lunch logged. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
