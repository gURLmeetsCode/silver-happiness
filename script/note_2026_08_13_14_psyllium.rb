# frozen_string_literal: true

# Note morning psyllium trial (Aug 13–14) and log 1 tbsp each morning.
#
# Observation: regularity improved; appetite unchanged so far.
#
#   bin/rails runner script/note_2026_08_13_14_psyllium.rb
#
# On the Pi:
#   set -a && source .env.production && set +a
#   bin/rails runner script/note_2026_08_13_14_psyllium.rb

DATES = [ Date.new(2026, 8, 13), Date.new(2026, 8, 14) ].freeze
NOTE = "Psyllium AM (1 tbsp): regularity ↑, appetite unchanged so far."
MEAL_NAME = "Psyllium husk (morning)"

product = Product.find_or_initialize_by(name: "Psyllium husk")
product.assign_attributes(
  calories_per_100g: 350, protein_per_100g: 0, carbs_per_100g: 80, fat_per_100g: 0,
  default_serving_g: 10, serving_label: "1 tbsp (~10 g)",
  notes: "Mostly fibre. ~35 kcal per tablespoon; take with plenty of water."
)
product.save!
puts "product: #{product.name}"

DATES.each do |date|
  log = DailyLog.find_or_create_by!(logged_on: date)

  existing_notes = [ log.notes, log.energy_notes ].compact_blank
  unless existing_notes.any? { |n| n.include?("Psyllium AM") }
    log.notes = [ log.notes, NOTE ].compact_blank.join(" · ")
    log.save!
    puts "  #{date}: noted"
  else
    puts "  #{date}: note already present"
  end

  entry = log.meal_entries.find_or_initialize_by(name: MEAL_NAME)
  entry.meal_type = :breakfast
  MealAssembler.new([
    { "product_id" => product.id, "quantity" => 1, "unit" => "serving" }
  ]).apply!(entry)
  entry.notes = NOTE
  entry.save!
  puts "  #{date}: #{entry.previously_new_record? ? "added" : "updated"} #{entry.name} (#{entry.calories} kcal)"
end

puts "==> Done"
