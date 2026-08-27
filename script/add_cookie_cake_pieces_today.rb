# frozen_string_literal: true

# Additive snack log — chocolate chip cookie cake pieces for today.
#
# Sizes (top surface; assumes ~1" thick cookie-cake slab):
#   - 3" × 2" ≈ 60 g (~64% of a typical ~94 g bakery slice)
#   - 2" × 2" ≈ 40 g
#
# Macros from commercial chocolate chip cookie cake labels (~447 kcal / 100 g).
#
#   bin/rails runner script/add_cookie_cake_pieces_today.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_cookie_cake_pieces_today.rb

DATE = ENV.fetch("LOGGED_ON", Date.current.to_s).then { |value| Date.parse(value) }

PRODUCT = {
  name: "Chocolate chip cookie cake",
  brand: nil,
  calories_per_100g: 447,
  protein_per_100g: 3.2,
  carbs_per_100g: 61.7,
  fat_per_100g: 20.2,
  default_serving_g: 60,
  serving_label: "3×2 in piece (~60 g, ~1 in thick)",
  notes: "Estimate from commercial chocolate chip cookie cake labels (~447 kcal/100 g). " \
         "Weight scaled from a typical ~94 g bakery slice: 3×2 in top ≈ 60 g; 2×2 in ≈ 40 g " \
         "(assumes ~1 in thick slab)."
}.freeze

PIECES = [
  {
    name: "Chocolate chip cookie cake (3×2 in)",
    meal_type: :snack,
    grams: 60,
    note: "3 in length × 2 in depth · ~1 in thick · estimate ~60 g"
  },
  {
    name: "Chocolate chip cookie cake (2×2 in)",
    meal_type: :snack,
    grams: 40,
    note: "2 in × 2 in · ~1 in thick · estimate ~40 g"
  }
].freeze

puts "==> Ensuring product exists"
product = Product.find_or_initialize_by(name: PRODUCT[:name])
product.assign_attributes(PRODUCT)
product.save!
puts "  product: #{product.name} (#{product.calories_per_100g} kcal/100 g)"

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id} existing meals=#{log.meal_entries.count}"

PIECES.each do |piece|
  entry = log.meal_entries.find_or_initialize_by(name: piece[:name])
  entry.meal_type = piece[:meal_type]
  MealAssembler.new([
    { "product_id" => product.id, "quantity" => piece[:grams], "unit" => "g" }
  ]).apply!(entry)
  entry.notes = piece[:note]
  entry.save!

  action = entry.previously_new_record? ? "added" : "updated"
  puts "  #{action}: #{entry.name} — #{entry.calories} kcal · #{entry.protein_g} g protein"
end

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
