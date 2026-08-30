# frozen_string_literal: true

# Additive snack/meal — ~30% of a maize baguette shared with husband.
#
# Product estimate from Open Food Facts “Ma baguette au maïs – Maïsano” (250 g loaf):
#   222 kcal · 7.6 g protein · 40 g carbs · 3.2 g fat / 100 g.
# Your share: ~30% of a 250 g baguette ≈ 75 g.
#
#   bin/rails runner script/add_mais_baguette_share_today.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_mais_baguette_share_today.rb

DATE = ENV.fetch("LOGGED_ON", Date.current.to_s).then { |value| Date.parse(value) }
SHARE_FRACTION = ENV.fetch("SHARE", "0.30").to_f
LOAF_G = 250
GRAMS = (LOAF_G * SHARE_FRACTION).round

PRODUCT = {
  name: "Baguette au maïs",
  brand: "Boulangerie / Maïsano-style",
  calories_per_100g: 222,
  protein_per_100g: 7.6,
  carbs_per_100g: 40.0,
  fat_per_100g: 3.2,
  default_serving_g: 75,
  serving_label: "~30% of 250 g loaf (~75 g)",
  notes: "Estimate from Open Food Facts maize baguette (~222 kcal/100 g). " \
         "Typical small baguette au maïs ~250 g."
}.freeze

MEAL_NAME = "Baguette au maïs (~30% of loaf)"

puts "==> Ensuring product exists"
product = Product.find_or_initialize_by(name: PRODUCT[:name])
product.assign_attributes(PRODUCT)
product.save!
puts "  product: #{product.name} (#{product.calories_per_100g} kcal/100 g)"

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id} existing meals=#{log.meal_entries.count}"

entry = log.meal_entries.find_or_initialize_by(name: MEAL_NAME)
entry.meal_type = :snack
MealAssembler.new([
  { "product_id" => product.id, "quantity" => GRAMS, "unit" => "g" }
]).apply!(entry)
entry.notes = "Shared baguette au maïs (~#{LOAF_G} g). Ate ~#{(SHARE_FRACTION * 100).round}% " \
              "(#{GRAMS} g); rest with husband."
entry.save!

action = entry.previously_new_record? ? "added" : "updated"
puts "  #{action}: #{entry.name} — #{entry.calories} kcal · #{entry.protein_g} g protein (#{GRAMS} g)"

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
