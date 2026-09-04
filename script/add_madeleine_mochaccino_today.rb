# frozen_string_literal: true

# Add Madeleine Café mochaccino (oat milk) to today's breakfast.
# Café publishes no labels — estimate for a specialty-café cup (~200 ml)
# espresso + chocolate + lait d'avoine (not a Starbucks Grande, not a macchiato).
#
#   bin/rails runner script/add_madeleine_mochaccino_today.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_madeleine_mochaccino_today.rb

DATE = ENV.fetch("LOGGED_ON", Date.current.to_s).then { |value| Date.parse(value) }

PRODUCT = {
  name: "Madeleine Café mochaccino (lait végétal)",
  brand: "Madeleine Café Nantes",
  beverage: true,
  calories_per_100g: 95.0,
  protein_per_100g: 1.5,
  carbs_per_100g: 15.0,
  fat_per_100g: 2.5,
  default_serving_g: 200,
  serving_label: "1 mochaccino · oat milk (~200 ml)",
  notes: "Estimate — Madeleine Café does not publish nutrition. Specialty-café cup " \
         "(smaller than Starbucks): espresso + chocolate + lait d'avoine ≈ 190 kcal. " \
         "Not a macchiato (~18 kcal). Midpoint of ~160–220 kcal range; +50–80 if whipped cream."
}.freeze

puts "==> Ensuring product"
product = Product.find_or_initialize_by(name: PRODUCT[:name])
product.assign_attributes(PRODUCT)
product.save!
puts "  #{product.name} · #{product.nutrition_for(product.default_serving_g)[:calories]} kcal / serving"

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id}"

breakfast = log.meal_entries.find { |m| m.meal_type_breakfast? }
mocha_already = breakfast&.items&.any? { |i| i.product_id == product.id }

if mocha_already
  puts "  mochaccino already on breakfast — leaving as-is"
else
  rows = []
  if breakfast
    breakfast.items.includes(:product).each do |item|
      next unless item.product

      rows << {
        "product_id" => item.product_id,
        "quantity" => item.grams.to_f,
        "unit" => "g"
      }
    end
  end
  rows << { "product_id" => product.id, "quantity" => 1, "unit" => "serving" }

  breakfast ||= log.meal_entries.build(meal_type: :breakfast)
  breakfast.meal_type = :breakfast
  MealAssembler.new(rows).apply!(breakfast, replace_notes: breakfast.notes.blank?)
  breakfast.name = if breakfast.name.blank? || breakfast.name.match?(/\AMeal /i)
    "Madeleine Café mochaccino (lait végétal)"
  elsif breakfast.name.exclude?("mochaccino") && breakfast.name.exclude?("mocha")
    "#{breakfast.name} + mochaccino"
  else
    breakfast.name
  end
  note = "Madeleine Café Nantes mochaccino estimate (~190 kcal, oat milk, no published label)."
  breakfast.notes = [ breakfast.notes, note ].compact_blank.uniq.join(" · ")
  breakfast.save!
  action = breakfast.previously_new_record? ? "created" : "updated"
  puts "  #{action} breakfast: #{breakfast.name} (#{breakfast.calories} kcal, #{breakfast.protein_g} g protein)"
end

log.reload
puts "==> Done. day kcal=#{log.total_calories} protein=#{log.total_protein.round(1)} g"
