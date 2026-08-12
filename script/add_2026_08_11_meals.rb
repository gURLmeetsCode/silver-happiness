# frozen_string_literal: true

# Additive one-shot: append 2026-08-11 meals (incl. Frédéric Brangeon croissant)
# without deleting anything already on that day.
#
# On the Pi (after deploy/migrate):
#   cd ~/silver-happiness
#   set -a && source .env.production && set +a
#   bin/rails runner script/add_2026_08_11_meals.rb

DATE = Date.new(2026, 8, 11)

PRODUCTS = [
  {
    name: "Croissant au beurre",
    brand: "Boulangerie Frédéric Brangeon",
    calories_per_100g: 424, protein_per_100g: 7.1, carbs_per_100g: 43.2, fat_per_100g: 23.3,
    default_serving_g: 55, serving_label: "1 croissant (~55 g)",
    notes: "CIQUAL artisanal butter croissant. Brangeon ~233 kcal for 55 g."
  },
  {
    name: "Yoonuts Muesli croustillant 4 fruits rouges",
    brand: "Yoonuts",
    calories_per_100g: 437, protein_per_100g: 10, carbs_per_100g: 59, fat_per_100g: 16,
    default_serving_g: 100, serving_label: "1 cup (~100 g)"
  },
  {
    name: "Yoonuts Muesli croustillant 4 noix",
    brand: "Yoonuts",
    calories_per_100g: 469, protein_per_100g: 11, carbs_per_100g: 55, fat_per_100g: 21,
    default_serving_g: 100, serving_label: "1 cup (~100 g)"
  },
  {
    name: "Brazil nuts",
    brand: nil,
    calories_per_100g: 659, protein_per_100g: 14.3, carbs_per_100g: 12.3, fat_per_100g: 67.1,
    default_serving_g: 133, serving_label: "1 cup whole (~133 g)"
  },
  {
    name: "Almonds",
    brand: nil,
    calories_per_100g: 579, protein_per_100g: 21.2, carbs_per_100g: 21.6, fat_per_100g: 49.9,
    default_serving_g: 72, serving_label: "0.5 cup whole (~72 g)"
  },
  {
    name: "Nectarine",
    brand: nil,
    calories_per_100g: 44, protein_per_100g: 1.2, carbs_per_100g: 8.9, fat_per_100g: 0.3,
    default_serving_g: 140, serving_label: "1 medium (~140 g)"
  },
  {
    name: "Tortilla chips",
    brand: nil,
    calories_per_100g: 488, protein_per_100g: 7.0, carbs_per_100g: 63.0, fat_per_100g: 23.0,
    default_serving_g: 50, serving_label: "1 handful (~50 g)"
  },
  {
    name: "Vegan cake-sale muffin with vegan feta",
    brand: nil,
    calories_per_100g: 280, protein_per_100g: 6, carbs_per_100g: 32, fat_per_100g: 14,
    default_serving_g: 125, serving_label: "1 muffin + feta (~125 g)"
  },
  {
    name: "Psyllium husk",
    brand: nil,
    calories_per_100g: 350, protein_per_100g: 0, carbs_per_100g: 80, fat_per_100g: 0,
    default_serving_g: 10, serving_label: "1 tbsp (~10 g)"
  }
].freeze

MEALS = [
  {
    name: "Croissant (Brangeon)",
    meal_type: :breakfast,
    items: [ { product: "Croissant au beurre", grams: 55 } ]
  },
  {
    name: "Bulk buy binge — cereals & nuts",
    meal_type: :snack,
    items: [
      { product: "Yoonuts Muesli croustillant 4 fruits rouges", grams: 150 },
      { product: "Yoonuts Muesli croustillant 4 noix", grams: 50 },
      { product: "Brazil nuts", grams: 133 },
      { product: "Almonds", grams: 72 }
    ]
  },
  {
    name: "White nectarine",
    meal_type: :snack,
    items: [ { product: "Nectarine", grams: 140 } ]
  },
  {
    name: "Tortilla chips (estimate handful)",
    meal_type: :snack,
    items: [ { product: "Tortilla chips", grams: 50 } ]
  },
  {
    name: "Vegan cake-sale muffin + feta",
    meal_type: :dinner,
    items: [ { product: "Vegan cake-sale muffin with vegan feta", grams: 125 } ]
  },
  {
    name: "Psyllium husk with water",
    meal_type: :snack,
    items: [ { product: "Psyllium husk", grams: 10 } ]
  }
].freeze

puts "==> Ensuring products exist"
PRODUCTS.each do |attrs|
  product = Product.find_or_initialize_by(name: attrs[:name])
  product.assign_attributes(attrs)
  product.save!
  puts "  product: #{product.name}"
end

log = DailyLog.find_or_create_by!(logged_on: DATE)
puts "==> Daily log #{DATE} id=#{log.id} existing meals=#{log.meal_entries.count}"

if log.respond_to?(:compulsive_eating_day=) && !log.compulsive_eating_day?
  log.update!(compulsive_eating_day: true)
  puts "  marked compulsive_eating_day"
end

added = 0
skipped = 0

MEALS.each do |spec|
  if log.meal_entries.exists?(name: spec[:name])
    puts "  skip (already present): #{spec[:name]}"
    skipped += 1
    next
  end

  rows = spec[:items].map do |item|
    product = Product.find_by!(name: item[:product])
    { "product_id" => product.id, "quantity" => item[:grams], "unit" => "g" }
  end

  entry = log.meal_entries.build(name: spec[:name], meal_type: spec[:meal_type])
  MealAssembler.new(rows).apply!(entry)
  entry.save!

  added += 1
  puts "  added: #{entry.name} (#{entry.calories} kcal, #{entry.protein_g} g protein)"
end

log.reload
puts "==> Done. added=#{added} skipped=#{skipped} total_meals=#{log.meal_entries.count} " \
     "kcal=#{log.total_calories}"
