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

Product.find_or_create_by!(name: "Coca-Cola Zero Zero mini") do |p|
  p.brand = "Coca-Cola"
  p.calories_per_100g = 0
  p.protein_per_100g = 0
  p.carbs_per_100g = 0
  p.fat_per_100g = 0
  p.default_serving_g = 150
  p.serving_label = "mini can (150 ml)"
  p.notes = "Zero Zero mini can — 0 kcal"
  p.quick_log = true
  p.beverage = true
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

Product.find_or_create_by!(name: "Jalapeños (pickled)") do |p|
  p.calories_per_100g = 20
  p.protein_per_100g = 0.5
  p.carbs_per_100g = 4
  p.fat_per_100g = 0.2
  p.default_serving_g = 15
  p.serving_label = "1 tbsp sliced"
  p.notes = "Jarred jalapeños — use tbsp for extra heat"
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

Product.find_or_create_by!(name: "All-purpose flour") do |p|
  p.calories_per_100g = 364
  p.protein_per_100g = 10
  p.carbs_per_100g = 76
  p.fat_per_100g = 1
  p.default_serving_g = 23.5
  p.serving_label = "1 medium pancake batter"
  p.notes = "Nora Cooks vegan pancakes — ~23.5 g flour per pancake (1/3 cup batter)"
end

Product.find_or_create_by!(name: "Strawberries") do |p|
  p.calories_per_100g = 32
  p.protein_per_100g = 0.7
  p.carbs_per_100g = 7.7
  p.fat_per_100g = 0.3
  p.default_serving_g = 50
  p.serving_label = "several small"
  p.notes = "Fresh strawberries — estimate ~50 g for a small handful"
end

# Frédéric Brangeon (La Chapelle-sur-Erdre) does not publish a label. Values are
# CIQUAL "Croissant au beurre, artisanal" per 100 g, portion sized as one croissant.
Product.find_or_create_by!(name: "Croissant au beurre")
croissant = Product.find_by!(name: "Croissant au beurre")
croissant.update!(
  brand: "Boulangerie Frédéric Brangeon",
  calories_per_100g: 424,
  protein_per_100g: 7.1,
  carbs_per_100g: 43.2,
  fat_per_100g: 23.3,
  default_serving_g: 55,
  serving_label: "1 croissant (~55 g)",
  notes: "CIQUAL artisanal butter croissant (Anses). Brangeon does not list macros — " \
         "~233 kcal for a 55 g croissant."
)

{
  "Yoonuts Muesli croustillant 4 fruits rouges" => {
    brand: "Yoonuts", calories_per_100g: 437, protein_per_100g: 10, carbs_per_100g: 59, fat_per_100g: 16,
    default_serving_g: 100, serving_label: "1 cup (~100 g)",
    notes: "Label: 437 kcal / 100 g. Cup ≈ 100 g for croustillant."
  },
  "Yoonuts Muesli croustillant 4 noix" => {
    brand: "Yoonuts", calories_per_100g: 469, protein_per_100g: 11, carbs_per_100g: 55, fat_per_100g: 21,
    default_serving_g: 100, serving_label: "1 cup (~100 g)",
    notes: "Label: 469 kcal / 100 g."
  },
  "Brazil nuts" => {
    calories_per_100g: 659, protein_per_100g: 14.3, carbs_per_100g: 12.3, fat_per_100g: 67.1,
    default_serving_g: 133, serving_label: "1 cup whole (~133 g)",
    notes: "USDA. A full cup is an extreme selenium dose."
  },
  "Almonds" => {
    calories_per_100g: 579, protein_per_100g: 21.2, carbs_per_100g: 21.6, fat_per_100g: 49.9,
    default_serving_g: 72, serving_label: "0.5 cup whole (~72 g)",
    notes: "Whole almonds; 0.5 cup ≈ 72 g."
  },
  "Nectarine" => {
    calories_per_100g: 44, protein_per_100g: 1.2, carbs_per_100g: 8.9, fat_per_100g: 0.3,
    default_serving_g: 140, serving_label: "1 medium (~140 g)",
    notes: "CIQUAL nectarine/brugnon raw."
  },
  "Tortilla chips" => {
    calories_per_100g: 488, protein_per_100g: 7.0, carbs_per_100g: 63.0, fat_per_100g: 23.0,
    default_serving_g: 50, serving_label: "1 handful (~50 g)",
    notes: "Typical corn tortilla chips average."
  },
  "Psyllium husk" => {
    calories_per_100g: 350, protein_per_100g: 0, carbs_per_100g: 80, fat_per_100g: 0,
    default_serving_g: 10, serving_label: "1 tbsp (~10 g)",
    notes: "~35 kcal per tbsp; mostly fibre."
  },
  "Cake salé" => {
    calories_per_100g: 176, protein_per_100g: 6.0, carbs_per_100g: 18.1, fat_per_100g: 9.1,
    default_serving_g: 85, serving_label: "1 cake salé (~85 g)",
    notes: "Muffin-mold cake salé (12): smoked tofu, pepper, onion, olives, vegan cheese. " \
           "No sun-dried tomatoes. ~150 kcal each (recipe estimate)."
  },
  "Sweet potato" => {
    calories_per_100g: 86, protein_per_100g: 1.5, carbs_per_100g: 18.3, fat_per_100g: 0.2,
    default_serving_g: 200, serving_label: "1 whole medium (~200 g)",
    notes: "CIQUAL patate douce, raw. Log raw weight before roasting."
  },
  "Yellow potato" => {
    calories_per_100g: 81, protein_per_100g: 1.9, carbs_per_100g: 16.7, fat_per_100g: 0.2,
    default_serving_g: 150, serving_label: "1 medium/small (~150 g)",
    notes: "CIQUAL pomme de terre peeled raw. Yellow/plain. Log raw weight before roasting."
  }
}.each do |name, attrs|
  product = Product.find_or_initialize_by(name: name)
  product.assign_attributes(attrs)
  product.save!
end

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

flour = Product.find_by!(name: "All-purpose flour")
strawberries = Product.find_by!(name: "Strawberries")

seed_template("noracooks-vegan-pancakes", "Nora Cooks vegan pancakes", :dinner, [
  [ flour, 23.5, "1 medium pancake (batter)" ],
  [ soja, 30, "soy milk in batter" ],
  [ puget_oil, 3.5, "oil in batter" ]
])

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

sweet_potato = Product.find_by!(name: "Sweet potato")
yellow_potato = Product.find_by!(name: "Yellow potato")

# Batch roast: 1 whole sweet potato + 4 medium/small yellow potatoes, cut into
# triangles, tossed with Puget oil + seasoning (seasoning ≈ 0 kcal).
# Template is the FULL tray — scale down when logging your plate share.
seed_template("roasted-sweet-yellow-potatoes", "Roasted sweet + yellow potatoes (batch)", :dinner, [
  [ sweet_potato, 200, "1 whole sweet potato (~200 g raw)" ],
  [ yellow_potato, 600, "4 medium/small yellow potatoes (~150 g each, raw)" ],
  [ puget_oil, 10, "1 tbsp Puget olive oil (adjust if you used more/less)" ]
])

barilla_pasta = Product.find_by!(name: "Barilla Fusilli Protein+")
homemade_dressing = Product.find_by!(name: "Homemade salad dressing")

seed_template("pasta-salad-tofu-dinner", "Pasta salad + tofu", :dinner, [
  [ barilla_pasta, 100, "100 g Barilla Fusilli Protein+ (dry)" ],
  [ tofu, 125, "125 g tofu nature (1 pavé)" ],
  [ homemade_dressing, 30, "2 tbsp homemade dressing" ]
])

# --- Personal history (Aug 6–7, 2026) ---
#
# These two days were hand-entered before the app could record them. A day that
# already exists belongs to whoever logged it, so the seed skips it entirely
# rather than reconciling field by field — re-running db:seed must never
# overwrite or delete a real check-in.
def seed_untouched_day(date)
  if DailyLog.exists?(logged_on: date)
    puts "  · #{date} already has a log — leaving it untouched"
    return
  end

  yield DailyLog.create!(logged_on: date)
end

seed_untouched_day(Date.new(2026, 8, 6)) do |aug6|
  aug6.update!(
    training_notes: "Rest · walked ~8 km Nantes (exhibitions, stairs)",
    notes: "Nantes outing. Evening: light salad + 100g tofu fumé."
  )

  aug6.meal_entries.create!(
    name: "Rest-day breakfast", meal_type: :breakfast, calories: 280, protein_g: 24,
    notes: "Yogurt + ½ scoop protein + strawberries + 1 tsp PB + chia + cinnamon + espresso"
  )
  aug6.meal_entries.create!(
    name: "Nantes lunch", meal_type: :lunch, calories: 750, protein_g: 18,
    notes: "Vegan burger + fries"
  )
  aug6.meal_entries.create!(
    name: "Nantes snacks + evening salad", meal_type: :dinner, calories: 650, protein_g: 18,
    notes: "Shared cake, 1½ cookies, 1× bubble tea 50% sugar, evening salad 100g tofu fumé, 2–3 tbsp dressing"
  )
end

seed_untouched_day(Date.new(2026, 8, 7)) do |aug7|
  power_salad = MealTemplate.find_by!(slug: "power-salad")
  banana_pb_snack = MealTemplate.find_by!(slug: "banana-pb-skyr-snack")

  aug7.update!(
    weight_kg: 59.0,
    weight_pre_run: true,
    run_km: 8,
    run_calories: 448,
    walk_km: 2.9,
    walk_calories: 159,
    training_notes: "6am fasted 8 km Runna + 2.9 km walk after",
    bed_time: "22:30",
    wake_time: "05:45",
    sleep_quality: 7,
    water_ml: 1750,
    feeling_check_in: "Light, good energy after run"
  )

  aug7.meal_entries.create!(
    name: "Run-day oats + protein", meal_type: :breakfast, calories: 348, protein_g: 36,
    meal_template: run_breakfast,
    notes: "40g oats + 35g Vegan Protein 360 + chia + cinnamon + nutmeg + espresso + soja foam"
  )

  aug7.meal_entries.create!(
    name: "Power salad lunch", meal_type: :lunch,
    calories: power_salad.total_calories,
    protein_g: power_salad.total_protein,
    carbs_g: power_salad.total_carbs,
    fat_g: power_salad.total_fat,
    meal_template: power_salad,
    notes: "125 g tofu + 120 g quinoa + 2 tbsp dressing"
  )

  aug7.meal_entries.create!(
    name: "Banana + PB + Skyr", meal_type: :snack,
    calories: banana_pb_snack.total_calories,
    protein_g: banana_pb_snack.total_protein,
    carbs_g: banana_pb_snack.total_carbs,
    fat_g: banana_pb_snack.total_fat,
    meal_template: banana_pb_snack
  )

  aug7.workouts.find_or_create_by!(activity_type: :run, calories_burned: 448) do |w|
    w.distance_km = 8
    w.notes = "6am fasted Runna run"
  end

  aug7.workouts.find_or_create_by!(activity_type: :walk, calories_burned: 159) do |w|
    w.distance_km = 2.9
    w.notes = "Walk after run"
  end
end

# One-tap quick log on dashboard / daily log
Product.find_or_create_by!(name: "Coca-Cola Zero Zero mini").update!(
  quick_log: true,
  default_serving_g: 150,
  serving_label: "mini can (150 ml)",
  calories_per_100g: 0,
  protein_per_100g: 0,
  carbs_per_100g: 0,
  fat_per_100g: 0
)
Product.find_by(name: "Banana")&.update!(quick_log: true)

puts "Baseline loaded — #{Product.count} products, #{MealTemplate.count} meal templates, #{DailyLog.count} daily logs."
