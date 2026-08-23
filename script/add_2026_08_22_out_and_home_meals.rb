# frozen_string_literal: true

# Additive log for 2026-08-22 — salad + bread + cookie out, then taco dinner at home.
#
# Out (estimates — not homemade):
#   - ~1 cup chickpea/carrot/pea/cornichon salad with watery white base + céleri
#     (white stalk veg — céleri branche / céleri-rave)
#   - 3 medium slices pain aux céréales (Boulangerie Capurro, centre Sucé-sur-Erdre)
#   - 1 U Bio sablé amandes-citron
#
# Home (taco base left out — add/adjust in the app):
#   - 4× Old El Paso Wrap Extra Fins (96 kcal)
#   - jalapeños (3 tbsp sliced — amount not specified; adjust if needed)
#   - 2× Sojasun yaourt nature pots
#   - 5 tbsp Cholula Chipotle
#   - +2 cups water (500 ml)
#
#   bin/rails runner script/add_2026_08_22_out_and_home_meals.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_2026_08_22_out_and_home_meals.rb

DATE = Date.new(2026, 8, 22)
WATER_ML = 500 # 2 cups

PRODUCTS = [
  {
    name: "Traiteur salad (carrot, pea, chickpea, cornichon, céleri)",
    brand: nil,
    calories_per_100g: 155,
    protein_per_100g: 4.5,
    carbs_per_100g: 12.0,
    fat_per_100g: 9.0,
    default_serving_g: 160,
    serving_label: "1 cup (~160 g)",
    notes: "Estimate for mixed French traiteur salad: shredded carrot, green peas, " \
           "chickpeas, cornichons, céleri (white stalk), watery mayo/yogurt-style base. " \
           "~155 kcal/100 g."
  },
  {
    name: "Pain aux céréales (Capurro Sucé)",
    brand: "Boulangerie Capurro",
    calories_per_100g: 286,
    protein_per_100g: 8.95,
    carbs_per_100g: 49.1,
    fat_per_100g: 3.9,
    default_serving_g: 42,
    serving_label: "1 medium slice (~42 g)",
    notes: "CIQUAL 7255 artisanal pain aux céréales/graines (286 kcal/100 g). " \
           "Likely Capurro centre-ville Sucé-sur-Erdre (pain bûcheron / céréales)."
  },
  {
    name: "U Bio sablés amandes citron",
    brand: "U Bio",
    calories_per_100g: 488,
    protein_per_100g: 8.0,
    carbs_per_100g: 61.0,
    fat_per_100g: 23.0,
    default_serving_g: 16.5,
    serving_label: "1 sablé (~16.5 g)",
    notes: "U Magasin sablés amandes-citron. Label: 488 kcal/100 g; 2 biscuits (33 g) = 161 kcal."
  },
].freeze

# Taco base left out on purpose — Natasha will add it in the app.
MEALS = [
  {
    name: "Traiteur salad + cereal bread + U almond-lemon cookie",
    meal_type: :lunch,
    items: [
      { product: "Traiteur salad (carrot, pea, chickpea, cornichon, céleri)", quantity: 1, unit: "serving" },
      { product: "Pain aux céréales (Capurro Sucé)", quantity: 3, unit: "serving" },
      { product: "U Bio sablés amandes citron", quantity: 1, unit: "serving" }
    ]
  },
  {
    name: "Taco wraps — Extra Fins, Sojasun, jalapeños, Cholula (taco base TBD)",
    meal_type: :dinner,
    items: [
      { product: "Old El Paso Wrap Extra Fins", quantity: 4, unit: "serving" },
      { product: "Jalapeños (pickled)", quantity: 3, unit: "tbsp" },
      { product: "Sojasun yaourt nature", quantity: 2, unit: "serving" },
      { product: "Cholula Chipotle sauce", quantity: 5, unit: "tbsp" }
    ]
  }
].freeze

puts "==> Ensuring products exist"
PRODUCTS.each do |attrs|
  product = Product.find_or_initialize_by(name: attrs[:name])
  product.assign_attributes(attrs)
  product.save!
  puts "  product: #{product.name}"
end

%w[
  Old\ El\ Paso\ Wrap\ Extra\ Fins
  Jalapeños\ (pickled)
  Sojasun\ yaourt\ nature
  Cholula\ Chipotle\ sauce
].each do |name|
  raise "Missing product: #{name}" unless Product.exists?(name: name)
end

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id} existing meals=#{log.meal_entries.count} water=#{log.water_ml} ml"

MEALS.each do |spec|
  rows = spec[:items].map do |item|
    product = Product.find_by!(name: item[:product])
    { "product_id" => product.id, "quantity" => item[:quantity], "unit" => item[:unit] }
  end

  entry = log.meal_entries.find_or_initialize_by(name: spec[:name])
  entry.meal_type = spec[:meal_type]
  MealAssembler.new(rows).apply!(entry)
  entry.save!

  action = entry.previously_new_record? ? "added" : "updated"
  puts "  #{action}: #{entry.name} (#{entry.calories} kcal, #{entry.protein_g} g protein)"
end

before_water = log.water_ml
if log.water_ml < WATER_ML
  log.add_water!(WATER_ML - log.water_ml)
  puts "  water: #{before_water} → #{log.reload.water_ml} ml (+#{WATER_ML} ml target for 2 cups)"
else
  # Ensure at least +500 from this log if water was already higher — only add if
  # we haven't already credited this script's water via a note flag.
  unless log.notes.to_s.include?("2026-08-22 +2 cups water")
    log.add_water!(WATER_ML)
    log.update!(notes: [ log.notes, "2026-08-22 +2 cups water" ].compact_blank.join(" · "))
    puts "  water: +#{WATER_ML} ml (now #{log.reload.water_ml} ml)"
  else
    puts "  water: already includes 2026-08-22 +2 cups (#{log.water_ml} ml)"
  end
end

# Mark the water note when we set from zero/low as well.
unless log.notes.to_s.include?("2026-08-22 +2 cups water")
  log.update!(notes: [ log.notes, "2026-08-22 +2 cups water" ].compact_blank.join(" · "))
end

log.reload
puts "==> Done. meals=#{log.meal_entries.count} kcal=#{log.total_calories} " \
     "protein=#{log.total_protein.round(1)} g water=#{log.water_ml} ml"
