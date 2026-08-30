# frozen_string_literal: true

# Additive entry — your share of a classic baguette au maïs shared with husband.
#
# Classic French baguette ≈ 250 g. Your share ≈ 25–30% → logged as 70 g (~28%).
# Macros: maize baguette ~222 kcal / 100 g (Open Food Facts baguette au maïs range).
#
#   bin/rails runner script/add_mais_baguette_share_today.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_mais_baguette_share_today.rb

DATE = ENV.fetch("LOGGED_ON", Date.current.to_s).then { |value| Date.parse(value) }
BAGUETTE_G = 250
# Midpoint of “maybe 25% or 30%” of a classic baguette.
SHARE_FRACTION = ENV.fetch("SHARE", "0.28").to_f
GRAMS = (BAGUETTE_G * SHARE_FRACTION).round

PRODUCT = {
  name: "Baguette au maïs",
  brand: nil,
  calories_per_100g: 222,
  protein_per_100g: 7.6,
  carbs_per_100g: 40.0,
  fat_per_100g: 3.2,
  default_serving_g: 70,
  serving_label: "~28% of classic baguette (~70 g)",
  notes: "Classic baguette au maïs (~250 g whole). Macros ~222 kcal/100 g (maize baguette estimate)."
}.freeze

MEAL_NAME = "Baguette au maïs (~25–30% of classic baguette)"
OLD_NAMES = [
  "Baguette au maïs (~30% of loaf)",
  MEAL_NAME
].freeze

puts "==> Ensuring product exists"
product = Product.find_or_initialize_by(name: PRODUCT[:name])
product.assign_attributes(PRODUCT)
product.save!
puts "  product: #{product.name} (#{product.calories_per_100g} kcal/100 g)"

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id}"

entry = OLD_NAMES.filter_map { |name| log.meal_entries.find_by(name: name) }.first
entry ||= log.meal_entries.build(meal_type: :snack)

entry.name = MEAL_NAME
entry.meal_type = :snack
MealAssembler.new([
  { "product_id" => product.id, "quantity" => GRAMS, "unit" => "g" }
]).apply!(entry)
entry.notes = "Classic baguette au maïs (~#{BAGUETTE_G} g). Ate ~25–30% (logged #{GRAMS} g); rest with husband."
entry.save!

action = entry.previously_new_record? ? "added" : "updated"
puts "  #{action}: #{entry.name} — #{entry.calories} kcal · #{entry.protein_g} g protein (#{GRAMS} g)"

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
