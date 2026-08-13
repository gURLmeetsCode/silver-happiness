# frozen_string_literal: true

# Additive / corrective lunch log for 2026-08-13 — L'Éthiquête (Nantes).
#
# What she ate:
#   - Iced Americano (35 ml espresso), black
#   - Bowl du moment (pasta bowl) — full
#   - Houmous — ~½ cup total for the table, shared ≈½ each (~¼ cup / ~60 g)
#   - Bread — one slice cut into 6–7 triangles; she had most (~¾ slice)
#   - Fondant au chocolat — half (shared equally)
#
# Restaurant publishes no labels; macros are estimates.
#
#   bin/rails runner script/add_2026_08_13_ethiquete_lunch.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_2026_08_13_ethiquete_lunch.rb

DATE = Date.new(2026, 8, 13)

# Prior script name — rewrite that entry if present so re-running corrects the day.
OLD_MEAL_NAMES = [
  "L'Éthiquête lunch — bowl + fondant + iced Americano",
  "L'Éthiquête lunch — bowl, houmous, bread, ½ fondant, Americano"
].freeze

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
    notes: "Black iced Americano. ~5 kcal for a 35 ml espresso shot. Water/ice add nothing."
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
    notes: "Estimate. Menu pasta bowl: chickpea pasta (GF), veg, beans, seeds, " \
           "vinaigrette, tofu rosso. ~850 kcal / ~40 g protein per bowl."
  },
  {
    name: "L'Éthiquête houmous (side)",
    brand: "L'Éthiquête Nantes",
    calories_per_100g: 270,
    protein_per_100g: 8.2,
    carbs_per_100g: 8.0,
    fat_per_100g: 22.0,
    # ½ cup hummus ≈ 120 g for the whole plate; product serving = that full ½ cup.
    default_serving_g: 120,
    serving_label: "½ cup houmous (~120 g, shared plate)",
    notes: "Menu: « Houmous à partager… Ou pas! ». Plate was ~½ cup total (~120 g), shared. " \
           "~270 kcal/100 g (restaurant/CIQUAL oilier range)."
  },
  {
    name: "Pain (with houmous side)",
    brand: "L'Éthiquête Nantes",
    calories_per_100g: 275,
    protein_per_100g: 9.0,
    carbs_per_100g: 53.0,
    fat_per_100g: 2.5,
    # One slice cut into 6–7 triangles — not a bread basket.
    default_serving_g: 35,
    serving_label: "1 slice cut into triangles (~35 g)",
    notes: "One slice of bread, cut into 6–7 triangles. ~35 g whole slice."
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
    notes: "Estimate for vegan chocolate fondant / moelleux. ~370 kcal per full portion."
  }
].freeze

MEAL = {
  name: "L'Éthiquête lunch — bowl, houmous, bread, ½ fondant, Americano",
  meal_type: :lunch,
  items: [
    { product: "Iced Americano (35 ml espresso)", quantity: 1, unit: "serving" },
    { product: "L'Éthiquête bowl du moment (pasta)", quantity: 1, unit: "serving" },
    # ½ cup total shared → her share ≈ ½ of that = ¼ cup ≈ 0.5 serving.
    { product: "L'Éthiquête houmous (side)", quantity: 0.5, unit: "serving" },
    # One slice in triangles; she had most → ~¾ slice.
    { product: "Pain (with houmous side)", quantity: 0.75, unit: "serving" },
    # Cake shared equally.
    { product: "L'Éthiquête fondant au chocolat", quantity: 0.5, unit: "serving" }
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
entry ||= log.meal_entries.find_by(name: OLD_MEAL_NAMES)
entry ||= log.meal_entries.build(meal_type: MEAL[:meal_type])

entry.name = MEAL[:name]
entry.meal_type = MEAL[:meal_type]
MealAssembler.new(rows).apply!(entry)
entry.notes = [
  "L'Éthiquête estimates. Houmous ≈ ½ of a ½-cup plate (shared); " \
  "bread ≈ ¾ of one sliced triangle slice; fondant = ½."
].compact_blank.join(" · ")
entry.save!

action = entry.previously_new_record? ? "added" : "updated"
puts "  #{action}: #{entry.name} (#{entry.calories} kcal, #{entry.protein_g} g protein)"

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
