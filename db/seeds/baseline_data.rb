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
  p.serving_label = "1 pot"
  p.notes = "Skyr nature — plain, unsweetened"
end

Product.find_or_create_by!(name: "Banana") do |p|
  p.calories_per_100g = 89
  p.protein_per_100g = 1.1
  p.carbs_per_100g = 23
  p.fat_per_100g = 0.3
  p.default_serving_g = 118
  p.serving_label = "1 medium"
end

Product.find_or_create_by!(name: "Purée de cacahuètes") do |p|
  p.brand = "Koro"
  p.calories_per_100g = 587
  p.protein_per_100g = 21
  p.fat_per_100g = 50
  p.default_serving_g = 5
  p.serving_label = "1 tsp"
end

tofu = Product.find_or_create_by!(name: "Tofu")
tofu.update!(
  brand: "Céréal Bio",
  calories_per_100g: 145,
  protein_per_100g: 14,
  carbs_per_100g: 0.8,
  fat_per_100g: 9,
  default_serving_g: 125,
  serving_label: "1 pavé (125 g)",
  notes: "Tofu nature à cuisiner — bio, sans sel. 250 g pack = 2 pavés. Label: 145 kcal · 14 g protein / 100 g."
)

Product.find_or_create_by!(name: "Tofu fumé")
tofu_fume = Product.find_by!(name: "Tofu fumé")
tofu_fume.update!(
  brand: "Céréal Bio",
  calories_per_100g: 164,
  protein_per_100g: 16,
  carbs_per_100g: 1,
  fat_per_100g: 10,
  default_serving_g: 100,
  serving_label: "1 portion (100 g)",
  notes: "Tofu fumé au bois de hêtre — exception days. 200 g pack = 2× 100 g. Label: 164 kcal · 16 g protein / 100 g."
)

Product.find_or_create_by!(name: "Quinoa cuit") do |p|
  p.calories_per_100g = 120
  p.protein_per_100g = 4.4
  p.carbs_per_100g = 21
  p.default_serving_g = 120
  p.serving_label = "120 g cooked (~¼ cup dry)"
  p.notes = "Weigh cooked quinoa for logging. ¼ cup dry tricolor ≈ 120 g cooked."
end

Product.find_or_create_by!(name: "Sojasun yaourt nature") do |p|
  p.brand = "Sojasun"
  p.calories_per_100g = 43
  p.protein_per_100g = 4.6
  p.carbs_per_100g = 0
  p.fat_per_100g = 2.7
  p.default_serving_g = 100
  p.serving_label = "1 pot (100 g)"
  p.notes = "Plain unsweetened soy yogurt — nature sans sucre (not Skyr)"
end

Product.find_or_create_by!(name: "Avocado") do |p|
  p.calories_per_100g = 160
  p.protein_per_100g = 2
  p.carbs_per_100g = 8.5
  p.fat_per_100g = 14.7
  p.default_serving_g = 75
  p.serving_label = "½ avocado"
end

Product.find_or_create_by!(name: "Cholula Chipotle sauce") do |p|
  p.brand = "Cholula"
  p.calories_per_100g = 0
  p.protein_per_100g = 0
  p.carbs_per_100g = 0
  p.fat_per_100g = 0
  p.default_serving_g = 15
  p.serving_label = "1 tbsp drizzle"
  p.notes = "Chipotle hot sauce — negligible calories per serving"
end

Product.find_or_create_by!(name: "Old El Paso Wrap Extra Fins") do |p|
  p.brand = "Old El Paso"
  p.calories_per_100g = 299
  p.protein_per_100g = 8.6
  p.carbs_per_100g = 53.2
  p.fat_per_100g = 5.4
  p.default_serving_g = 32
  p.serving_label = "1 wrap"
  p.notes = "Extra thin wheat tortilla — 96 kcal per 32 g wrap (pack of 6)"
end

Product.find_or_create_by!(name: "Baby potatoes") do |p|
  p.calories_per_100g = 77
  p.protein_per_100g = 1.8
  p.carbs_per_100g = 15
  p.fat_per_100g = 0.1
  p.default_serving_g = 225
  p.serving_label = "200–250 g"
  p.notes = "Raw weight before roasting/boiling"
end

Product.find_or_create_by!(name: "Red pepper") do |p|
  p.calories_per_100g = 31
  p.protein_per_100g = 1
  p.carbs_per_100g = 6
  p.fat_per_100g = 0.3
  p.default_serving_g = 80
  p.serving_label = "1 pepper"
end

Product.find_or_create_by!(name: "Nutritional yeast") do |p|
  p.calories_per_100g = 400
  p.protein_per_100g = 50
  p.carbs_per_100g = 33
  p.fat_per_100g = 7
  p.default_serving_g = 10
  p.serving_label = "2 tbsp"
  p.notes = "Optional — for scramble"
end

Product.find_or_create_by!(name: "Barilla Fusilli Protein+")
barilla_pasta = Product.find_by!(name: "Barilla Fusilli Protein+")
barilla_pasta.update!(
  brand: "Barilla",
  calories_per_100g: 354,
  protein_per_100g: 20,
  carbs_per_100g: 63,
  fat_per_100g: 1.7,
  default_serving_g: 100,
  serving_label: "100 g dry",
  notes: "Pâtes fusilli Protein+ — log dry weight. Label: 354 kcal · 20 g protein / 100 g (semoule + protéines de pois)."
)

Product.find_or_create_by!(name: "Homemade salad dressing")
homemade_dressing = Product.find_by!(name: "Homemade salad dressing")
homemade_dressing.update!(
  calories_per_100g: 533,
  protein_per_100g: 0,
  carbs_per_100g: 0,
  fat_per_100g: 56,
  default_serving_g: 30,
  serving_label: "2 tbsp",
  notes: "Your eyeball batch — ~80 kcal per tbsp measured onto salad (2 tbsp = ~160 kcal)."
)

Product.find_or_create_by!(name: "Zucchini")
zucchini = Product.find_by!(name: "Zucchini")
zucchini.update!(
  calories_per_100g: 17,
  protein_per_100g: 1.2,
  carbs_per_100g: 3.1,
  fat_per_100g: 0.3,
  default_serving_g: 100,
  serving_label: "½ zucchini (~100 g)",
  notes: "Raw — half medium zucchini"
)

Product.find_or_create_by!(name: "Puget Huile d'olive vierge extra")
puget_oil = Product.find_by!(name: "Puget Huile d'olive vierge extra")
puget_oil.update!(
  brand: "Puget",
  calories_per_100g: 900,
  protein_per_100g: 0,
  carbs_per_100g: 0,
  fat_per_100g: 100,
  default_serving_g: 10,
  serving_label: "1 tbsp (10 g)",
  notes: "Label: 900 kcal · 100 g fat / 100 ml. 1 tbsp = 10 g = 90 kcal."
)

def seed_template(slug, name, meal_type, items)
  template = MealTemplate.find_or_create_by!(slug: slug) do |t|
    t.name = name
    t.meal_type = meal_type
  end
  template.update!(name: name, meal_type: meal_type)
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

homemade_dressing = Product.find_by!(name: "Homemade salad dressing")

seed_template("power-salad", "Power salad lunch", :lunch, [
  [ tofu, 125, "125 g tofu nature (1 pavé)" ],
  [ quinoa, 120, "120 g cooked (~¼ cup dry)" ],
  [ homemade_dressing, 30, "2 tbsp homemade dressing" ]
])

banana = Product.find_by!(name: "Banana")
seed_template("banana-pb-skyr-snack", "Banana + PB + Skyr", :snack, [
  [ banana, 118, "1 whole banana, sliced" ],
  [ koro, 8, "1 large tsp Koro PB" ],
  [ skyr, 15, "1 tbsp plain Skyr" ]
])

sojasun_nature = Product.find_by!(name: "Sojasun yaourt nature")
avocado = Product.find_by!(name: "Avocado")
cholula = Product.find_by!(name: "Cholula Chipotle sauce")
wrap = Product.find_by!(name: "Old El Paso Wrap Extra Fins")
baby_potatoes = Product.find_by!(name: "Baby potatoes")
red_pepper = Product.find_by!(name: "Red pepper")
nutritional_yeast = Product.find_by!(name: "Nutritional yeast")

seed_template("chipotle-yogurt-salad", "Chipotle tofu wrap", :lunch, [
  [ wrap, 32, "1 Old El Paso Extra Fins wrap" ],
  [ tofu, 125, "125 g tofu nature (1 pavé)" ],
  [ avocado, 75, "½ avocado" ],
  [ sojasun_nature, 100, "1 pot Sojasun nature plain (100 g)" ],
  [ cholula, 15, "Cholula Chipotle drizzle" ]
])

seed_template("tofu-scramble-potatoes", "Tofu scramble + baby potatoes", :breakfast, [
  [ tofu, 200, "200 g extra-firm tofu" ],
  [ baby_potatoes, 225, "225 g baby potatoes" ],
  [ red_pepper, 80, "1 red pepper" ],
  [ avocado, 56, "¼–½ avocado (~56 g)" ],
  [ nutritional_yeast, 10, "2 tbsp nutritional yeast (optional)" ]
])

barilla_pasta = Product.find_by!(name: "Barilla Fusilli Protein+")
homemade_dressing = Product.find_by!(name: "Homemade salad dressing")

seed_template("pasta-salad-tofu-dinner", "Pasta salad + tofu", :dinner, [
  [ barilla_pasta, 100, "100 g Barilla Fusilli Protein+ (dry)" ],
  [ tofu, 125, "125 g tofu nature (1 pavé)" ],
  [ homemade_dressing, 30, "2 tbsp homemade dressing" ]
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

power_salad = MealTemplate.find_by!(slug: "power-salad")
banana_pb_snack = MealTemplate.find_by!(slug: "banana-pb-skyr-snack")

aug7.meal_entries.find_or_initialize_by(name: "Run-day oats + protein").tap do |e|
  e.assign_attributes(
    meal_type: :breakfast, calories: 348, protein_g: 36,
    meal_template: run_breakfast,
    notes: "40g oats + 35g Vegan Protein 360 + chia + cinnamon + nutmeg + espresso + soja foam"
  )
  e.save!
end

aug7.meal_entries.find_or_initialize_by(name: "Power salad lunch").tap do |e|
  e.assign_attributes(
    meal_type: :lunch,
    calories: power_salad.total_calories,
    protein_g: power_salad.total_protein,
    carbs_g: power_salad.total_carbs,
    fat_g: power_salad.total_fat,
    meal_template: power_salad,
    notes: "125 g tofu + 120 g quinoa + 2 tbsp dressing"
  )
  e.save!
end

aug7.meal_entries.find_or_initialize_by(name: "Banana + PB + Skyr").tap do |e|
  e.assign_attributes(
    meal_type: :snack,
    calories: banana_pb_snack.total_calories,
    protein_g: banana_pb_snack.total_protein,
    carbs_g: banana_pb_snack.total_carbs,
    fat_g: banana_pb_snack.total_fat,
    meal_template: banana_pb_snack
  )
  e.save!
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
