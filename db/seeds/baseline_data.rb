# frozen_string_literal: true

# Your real products, meal templates, and logged days — not fake sample data.
# Safe to run in production on first deploy.

puts "Loading baseline data (products, templates, your logs)..."

Product.find_or_create_by!(name: "Flocons d'avoine complets sans gluten") do |p|
  p.brand = "Generic"
  p.calories_per_100g = 364
  p.protein_per_100g = 12
  p.carbs_per_100g = 59
  p.fat_per_100g = 6.7
  p.default_serving_g = 40
  p.serving_label = "1 scoop"
end

protein_powder = Product.find_or_create_by!(name: "Vegan Protein 360 vanille") do |p|
  p.brand = "Platinum Innovation"
  p.calories_per_100g = 354
  p.protein_per_100g = 80
  p.carbs_per_100g = 6
  p.fat_per_100g = 3
  p.default_serving_g = 35
  p.serving_label = "1 scoop"
end

Product.find_or_create_by!(name: "Chia seeds") do |p|
  p.calories_per_100g = 486
  p.protein_per_100g = 17
  p.carbs_per_100g = 42
  p.fat_per_100g = 31
  p.default_serving_g = 15
  p.serving_label = "1 tbsp"
  p.notes = "Estimated values"
end

Product.find_or_create_by!(name: "Soja sans sucre") do |p|
  p.brand = "Bjorg"
  p.calories_per_100g = 43
  p.protein_per_100g = 3.9
  p.default_serving_g = 15
  p.serving_label = "1 tbsp foam"
end

Product.find_or_create_by!(name: "Skyr vegan") do |p|
  p.brand = "Sojasun"
  p.calories_per_100g = 60
  p.protein_per_100g = 7
  p.default_serving_g = 150
end

Product.find_or_create_by!(name: "Purée de cacahuètes") do |p|
  p.brand = "Koro"
  p.calories_per_100g = 587
  p.protein_per_100g = 21
  p.fat_per_100g = 50
  p.default_serving_g = 5
  p.serving_label = "1 tsp"
end

Product.find_or_create_by!(name: "Tofu") do |p|
  p.brand = "Céréal Bio"
  p.calories_per_100g = 145
  p.protein_per_100g = 14.4
  p.default_serving_g = 125
  p.serving_label = "1 pavé"
end

Product.find_or_create_by!(name: "Quinoa cuit") do |p|
  p.calories_per_100g = 120
  p.protein_per_100g = 4.4
  p.carbs_per_100g = 21
  p.default_serving_g = 120
end

def seed_template(slug, name, meal_type, items)
  template = MealTemplate.find_or_create_by!(slug: slug) do |t|
    t.name = name
    t.meal_type = meal_type
  end
  template.meal_template_items.destroy_all
  items.each do |product, quantity_g, label|
    template.meal_template_items.create!(product: product, quantity_g: quantity_g, label: label)
  end
  template
end

oats = Product.find_by!(name: "Flocons d'avoine complets sans gluten")
skyr = Product.find_by!(name: "Skyr vegan")
koro = Product.find_by!(name: "Purée de cacahuètes")
chia = Product.find_by!(name: "Chia seeds")
soja = Product.find_by!(name: "Soja sans sucre")
tofu = Product.find_by!(name: "Tofu")
quinoa = Product.find_by!(name: "Quinoa cuit")

run_breakfast = seed_template("run-breakfast", "Run-day oats + protein", :breakfast, [
  [ oats, 40, "40g oats" ],
  [ protein_powder, 35, "35g protein" ],
  [ chia, 15, "1 tbsp chia" ],
  [ soja, 15, "soja foam" ]
])

seed_template("rest-breakfast", "Yogurt + ½ protein", :breakfast, [
  [ skyr, 150, "150g skyr" ],
  [ protein_powder, 17.5, "½ scoop protein" ],
  [ koro, 5, "1 tsp PB" ],
  [ chia, 15, "1 tbsp chia" ]
])

seed_template("power-salad", "Power salad lunch", :lunch, [
  [ tofu, 125, "125g tofu" ],
  [ quinoa, 120, "120g quinoa" ]
])

# --- Aug 6, 2026 (real day — Nantes outing) ---
aug6 = DailyLog.find_or_create_by!(logged_on: Date.new(2026, 8, 6)) do |log|
  log.training_notes = "Rest · walked ~8 km Nantes (exhibitions, stairs)"
  log.portions_on_plan = :mostly
  log.notes = "Nantes outing. Evening: light salad + 100g tofu fumé."
end

aug6.meal_entries.find_or_create_by!(name: "Rest-day breakfast") do |e|
  e.meal_type = :breakfast
  e.calories = 280
  e.protein_g = 24
  e.notes = "Yogurt + ½ scoop protein + strawberries + 1 tsp PB + chia + cinnamon + espresso"
end

aug6.meal_entries.find_or_create_by!(name: "Nantes lunch") do |e|
  e.meal_type = :lunch
  e.calories = 750
  e.protein_g = 18
  e.notes = "Vegan burger + fries"
end

aug6.meal_entries.find_or_create_by!(name: "Nantes snacks + evening salad") do |e|
  e.meal_type = :dinner
  e.calories = 650
  e.protein_g = 18
  e.notes = "Shared cake, 1½ cookies, 1× bubble tea 50% sugar, evening salad 100g tofu fumé, 2–3 tbsp dressing"
end

# --- Aug 7, 2026 (today — real logged data) ---
aug7 = DailyLog.find_or_create_by!(logged_on: Date.new(2026, 8, 7)) do |log|
  log.weight_kg = 59.0
  log.weight_pre_run = true
  log.run_km = 8
  log.run_calories = 448
  log.walk_km = 2.9
  log.walk_calories = 159
  log.training_notes = "6am fasted 8 km Runna + 2.9 km walk after"
  log.portions_on_plan = :yes
  log.bed_time = Time.zone.parse("22:30")
  log.wake_time = Time.zone.parse("05:45")
  log.sleep_quality = 7
  log.water_ml = 1750
  log.feeling_check_in = "Light, good energy after run"
end

aug7.meal_entries.find_or_create_by!(name: "Run-day oats + protein") do |e|
  e.meal_type = :breakfast
  e.calories = 348
  e.protein_g = 36
  e.notes = "40g oats + 35g Vegan Protein 360 + chia + cinnamon + nutmeg + espresso + soja foam"
  e.meal_template = run_breakfast
end

aug7.workouts.find_or_create_by!(activity_type: :run, calories_burned: 448) do |w|
  w.distance_km = 8
  w.notes = "6am fasted Runna run"
end

aug7.workouts.find_or_create_by!(activity_type: :walk, calories_burned: 159) do |w|
  w.distance_km = 2.9
  w.notes = "Walk after run"
end

puts "Baseline loaded — #{Product.count} products, #{MealTemplate.count} meal templates, #{DailyLog.count} daily logs."
