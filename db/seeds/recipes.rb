# frozen_string_literal: true

puts "Loading recipes..."

def seed_recipe(slug, attrs, ingredients, steps)
  recipe = Recipe.find_or_create_by!(slug: slug) do |r|
    r.assign_attributes(attrs.except(:meal_template_slug))
  end

  # A recipe you wrote yourself can land on a seeded slug (e.g. "baked-tofu").
  # Seeding rewrites ingredients wholesale, so never touch one you own.
  if recipe.user_created?
    puts "  · #{slug} is your own recipe — leaving it untouched"
    return recipe
  end

  if attrs[:meal_template_slug]
    recipe.meal_template = MealTemplate.find_by!(slug: attrs[:meal_template_slug])
  end

  recipe.update!(attrs.except(:meal_template_slug, :calories, :protein_g))
  recipe.recipe_ingredients.destroy_all

  ingredients.each_with_index do |item, i|
    category, amount, name, product_name, quantity_g = item
    prod = if product_name.present? && quantity_g.to_f.positive?
      Product.find_by(name: product_name)
    end

    recipe.recipe_ingredients.create!(
      grocery_category: category,
      amount: amount,
      name: prod ? prod.name : name,
      product: prod,
      quantity_g: quantity_g,
      position: i
    )
  end

  recipe.update!(steps: steps) if steps.present?
  recipe.sync_macros_from_ingredients!
  recipe.meal_template&.update!(water_suggestion_ml: recipe.water_suggestion_ml)
  recipe
end

unless $RECIPES_SEED_HELPER_ONLY

seed_recipe "baked-tofu", {
  name: "Baked tofu (batch prep)",
  meal_type: :prep,
  regular_meal: true,
  prep_time: "35 min",
  serves: 4,
  position: 0,
  description: "Make once, use in power salads and stir-fries all week. Weigh 150 g per salad serving."
}, [
  [ :protein, "600 g", "firm tofu, pressed and cubed", "Tofu", 600 ],
  [ :fats, "2 tbsp", "olive oil" ],
  [ :pantry, "2 tbsp", "soy sauce" ],
  [ :pantry, "1 tsp", "garlic powder" ],
  [ :pantry, "1 tsp", "smoked paprika (optional)" ],
  [ :pantry, nil, "black pepper" ]
], <<~STEPS
  1. Heat oven to 200°C. Line a baking tray.
  2. Toss tofu with oil, soy sauce, and spices.
  3. Spread in a single layer. Bake 25–30 min, flip once, until golden.
  4. Store in fridge up to 4 days. Weigh 150 g per salad.
STEPS

seed_recipe "quinoa-batch", {
  name: "Quinoa (batch for the week)",
  meal_type: :prep,
  regular_meal: true,
  prep_time: "20 min",
  serves: 4,
  protein_g: 5,
  calories: 140,
  position: 1,
  description: "Cook once, divide into 4× 120 g portions for power salads."
}, [
  [ :carbs, "160 g", "dry quinoa (~1 cup)" ],
  [ :pantry, "480 ml", "water or vegetable broth" ],
  [ :pantry, nil, "pinch of salt" ]
], <<~STEPS
  1. Rinse quinoa. Combine with liquid in a pot.
  2. Boil, cover, simmer 15 min until water is absorbed.
  3. Fluff, cool, divide into 4 containers (120 g each).
STEPS

seed_recipe "balsamic-dressing", {
  name: "Measured balsamic dressing",
  meal_type: :prep,
  regular_meal: true,
  prep_time: "5 min",
  serves: 4,
  calories: 45,
  position: 2,
  description: "Do not free-pour — use exactly 2 tbsp per salad (~45 kcal per serving)."
}, [
  [ :pantry, "4 tbsp", "balsamic vinegar" ],
  [ :fats, "2 tbsp", "olive oil" ],
  [ :pantry, "1 tsp", "Dijon mustard" ],
  [ :pantry, "1 tsp", "maple syrup or agave (optional)" ],
  [ :pantry, nil, "salt and pepper" ]
], <<~STEPS
  1. Shake in a small jar. Store fridge up to 1 week.
  2. Use exactly 2 tbsp per salad. Pour into a spoon first if helpful.
  3. Lighter option: lemon juice + 1 tsp olive oil + salt.
STEPS

# --- Breakfast (your regular meals) ---

seed_recipe "run-day-oats", {
  name: "Run-day oats + protein",
  meal_type: :breakfast,
  regular_meal: true,
  meal_template_slug: "run-breakfast",
  prep_time: "5 min",
  serves: 1,
  position: 0,
  description: "Post-run breakfast within 60–90 min after your 6am fasted run. Your usual — keep this."
}, [
  [ :carbs, "40 g", "rolled oats", "Flocons d'avoine complets sans gluten", 40 ],
  [ :protein, "35 g", "Vegan Protein 360", "Vegan Protein 360 vanille", 35 ],
  [ :pantry, "1 tbsp", "chia seeds", "Chia seeds", 15 ],
  [ :pantry, nil, "cinnamon and nutmeg to taste", nil, nil ],
  [ :pantry, nil, "water or soy milk to cook", nil, nil ],
  [ :pantry, "1 tbsp", "Soja sans sucre", "Soja sans sucre", 15 ],
  [ :pantry, nil, "3-shot espresso", nil, nil ]
], <<~STEPS
  1. After your run: cook oats with liquid 3–5 min.
  2. Stir in protein powder off heat (avoids clumping).
  3. Top with chia, cinnamon, nutmeg. Coffee alongside.
STEPS

seed_recipe "rest-day-yogurt", {
  name: "Rest-day yogurt + ½ protein",
  meal_type: :breakfast,
  regular_meal: true,
  meal_template_slug: "rest-breakfast",
  prep_time: "2 min",
  serves: 1,
  position: 1,
  description: "Mon/Thu rest days. On Wednesday strength days, use 200 g yogurt if still hungry."
}, [
  [ :protein, "150 g", "Sojasun Skyr", "Skyr vegan", 150 ],
  [ :protein, "17.5 g", "½ scoop protein", "Vegan Protein 360 vanille", 17.5 ],
  [ :produce, "~6", "strawberries, sliced", nil, nil ],
  [ :fats, "1 tsp", "Koro peanut butter", "Purée de cacahuètes", 5 ],
  [ :pantry, "1 tbsp", "chia seeds", "Chia seeds", 15 ],
  [ :pantry, nil, "cinnamon to taste", nil, nil ],
  [ :pantry, nil, "3-shot espresso", nil, nil ]
], <<~STEPS
  1. Stir protein powder into yogurt first (smoother than dumping on top).
  2. Add strawberries, PB, chia, cinnamon. Coffee alongside.
STEPS

# --- Lunch ---

seed_recipe "power-salad", {
  name: "Power salad lunch",
  meal_type: :lunch,
  regular_meal: true,
  meal_template_slug: "power-salad",
  prep_time: "5 min (if prepped)",
  serves: 1,
  position: 0,
  description: "Default weekday lunch Mon–Thu. One measured bowl — no refills. Quinoa is logged by cooked weight (120 g ≈ ¼ cup dry before cooking). Macros from tofu + quinoa + 2 tbsp dressing; salad veg extra."
}, [
  [ :produce, "80 g", "mâche or mesclun mix (2 big handfuls)", nil, nil ],
  [ :produce, "10", "cherry tomatoes, halved", nil, nil ],
  [ :produce, "½", "cucumber, sliced", nil, nil ],
  [ :produce, "¼", "red pepper, sliced", nil, nil ],
  [ :produce, "1 small fist", "red cabbage, shredded (optional)", nil, nil ],
  [ :produce, "2 tbsp", "shredded carrot (optional)", nil, nil ],
  [ :protein, "125 g", "tofu nature (1 pavé)", "Tofu", 125 ],
  [ :carbs, "120 g", "cooked quinoa (~¼ cup dry)", "Quinoa cuit", 120 ],
  [ :pantry, "2 tbsp", "homemade dressing (measured)", "Homemade salad dressing", 30 ]
], <<~STEPS
  1. Add greens to your usual large bowl.
  2. Top with veg, then quinoa, then tofu.
  3. Drizzle exactly 2 tbsp dressing. Eat from this bowl only — no refills.
STEPS

seed_recipe "chipotle-yogurt-salad", {
  name: "Chipotle tofu wrap",
  meal_type: :lunch,
  regular_meal: true,
  meal_template_slug: "chipotle-yogurt-salad",
  prep_time: "5 min",
  serves: 1,
  position: 1,
  description: "Salad wrapped in an Old El Paso Extra Fins tortilla (32 g, 96 kcal). 125 g Céréal Bio tofu nature (1 pavé), one 100 g pot Sojasun nature plain, avocado, and Cholula. Use Tofu fumé only on exception days. Greens and veg are extra."
}, [
  [ :carbs, "1 wrap", "Old El Paso Wrap Extra Fins (32 g)", "Old El Paso Wrap Extra Fins", 32 ],
  [ :produce, "2 big handfuls", "mixed greens (mâche / mesclun)", nil, nil ],
  [ :produce, "1 handful", "baby spinach", nil, nil ],
  [ :produce, "10", "cherry tomatoes, halved", nil, nil ],
  [ :produce, "¼", "red pepper, sliced", nil, nil ],
  [ :produce, "6–8 slices", "jalapeños (from jar or fresh)", nil, nil ],
  [ :protein, "125 g", "tofu nature, cubed (1 pavé)", "Tofu", 125 ],
  [ :fats, "½", "avocado", "Avocado", 75 ],
  [ :protein, "1 pot", "Sojasun yaourt nature plain (100 g)", "Sojasun yaourt nature", 100 ],
  [ :pantry, "1 tbsp", "Cholula Chipotle hot sauce", "Cholula Chipotle sauce", 15 ]
], <<~STEPS
  1. Fill a large bowl with mixed greens, spinach, cherry tomatoes, and red pepper.
  2. Add 125 g cubed Céréal Bio tofu nature (1 pavé), ½ avocado, and sliced jalapeños.
  3. Spoon one 100 g pot of plain Sojasun nature over the salad (creamy dressing).
  4. Drizzle Cholula Chipotle to taste. Toss gently.
  5. Pile into one Old El Paso Extra Fins wrap and roll, or eat open-faced.
  6. Log with one tap — tracked: ~440 kcal · ~26 g protein (wrap + tofu + yogurt + avocado).
STEPS

seed_recipe "tofu-scramble-potatoes", {
  name: "Tofu scramble with baby potatoes",
  meal_type: :breakfast,
  regular_meal: true,
  meal_template_slug: "tofu-scramble-potatoes",
  prep_time: "25 min",
  serves: 1,
  position: 2,
  description: "Crumbled tofu with roasted baby potatoes, pepper, and avocado. Spinach optional on the side. Ketchup or hot sauce on top — not counted in macros."
}, [
  [ :protein, "200 g", "extra-firm tofu, crumbled", "Tofu", 200 ],
  [ :carbs, "225 g", "baby potatoes, roasted or boiled", "Baby potatoes", 225 ],
  [ :produce, "1", "red pepper, diced", "Red pepper", 80 ],
  [ :produce, "1 handful", "spinach or mixed salad (optional)", nil, nil ],
  [ :fats, "¼–½", "avocado", "Avocado", 56 ],
  [ :pantry, "2 tbsp", "nutritional yeast (optional)", "Nutritional yeast", 10 ],
  [ :pantry, "½ tsp", "garlic powder", nil, nil ],
  [ :pantry, "½ tsp", "onion powder", nil, nil ],
  [ :pantry, "pinch", "turmeric (optional, for colour)", nil, nil ],
  [ :pantry, nil, "salt, pepper", nil, nil ],
  [ :pantry, "1 tsp", "olive oil for pan (optional)", nil, nil ],
  [ :pantry, nil, "ketchup or hot sauce to serve", nil, nil ]
], <<~STEPS
  1. Roast or boil 200–250 g baby potatoes until tender (225 g logged).
  2. Crumble 200 g extra-firm tofu. Sauté pepper in a non-stick pan, add tofu.
  3. Season with garlic powder, onion powder, turmeric, salt, and pepper. Cook 5–7 min.
  4. Stir in nutritional yeast if using. Serve with potatoes, avocado, and ketchup/hot sauce.
  5. Add a handful of spinach on the side if you like.
  6. Log with one tap — tracked: ~620 kcal · ~40 g protein.
STEPS

# --- Dinners ---

seed_recipe "pasta-salad-tofu-dinner", {
  name: "Pasta salad + tofu",
  meal_type: :dinner,
  regular_meal: true,
  meal_template_slug: "pasta-salad-tofu-dinner",
  prep_time: "20 min",
  serves: 1,
  position: 4,
  description: "Friday run-day dinner. Salad base (greens, tomatoes, cucumber, red pepper, fresh basil) + measured dressing + Barilla Protein+ fusilli + tofu. No cabbage or carrots. Macros from pasta, tofu, and 2 tbsp dressing; salad veg and basil extra."
}, [
  [ :produce, "2 big handfuls", "mâche or mesclun mix", nil, nil ],
  [ :produce, "10", "cherry tomatoes, halved", nil, nil ],
  [ :produce, "½", "cucumber, sliced", nil, nil ],
  [ :produce, "¼", "red pepper, sliced", nil, nil ],
  [ :produce, "1 handful", "fresh basil leaves", nil, nil ],
  [ :pantry, "2 tbsp", "homemade dressing (measured)", "Homemade salad dressing", 30 ],
  [ :carbs, "100 g", "Barilla Fusilli Protein+ (dry weight)", "Barilla Fusilli Protein+", 100 ],
  [ :protein, "125 g", "tofu nature, cubed (1 pavé)", "Tofu", 125 ]
], <<~STEPS
  1. Cook 100 g dry Barilla Protein+ fusilli. Drain — weigh dry before cooking.
  2. Fill a bowl with greens, cherry tomatoes, cucumber, red pepper, and fresh basil.
  3. Measure exactly 2 tbsp of your homemade dressing onto the salad.
  4. Add warm fusilli and 125 g cubed Céréal Bio tofu nature. Toss or serve combined.
  5. One plate only — put leftovers away before eating.
  6. Log with one tap — tracked: ~695 kcal · ~38 g protein (pasta + tofu + dressing).
STEPS

seed_recipe "mexican-zucchini-bowl", {
  name: "Mexican zucchini bowl",
  meal_type: :dinner,
  regular_meal: true,
  prep_time: "25 min",
  serves: 2,
  protein_g: 22,
  calories: 520,
  position: 0,
  description: "Dinner template 1. One bowl = one serving. Put leftovers away before eating."
}, [
  [ :produce, "400 g", "zucchini, half-moons" ],
  [ :produce, "1", "red pepper, sliced" ],
  [ :produce, "1 small", "onion, sliced" ],
  [ :fats, "1 tbsp", "olive oil" ],
  [ :pantry, "1 tsp", "cumin" ],
  [ :pantry, "1 tsp", "chili powder" ],
  [ :protein, "240 g", "canned black beans, rinsed (120 g per serving)" ],
  [ :carbs, "160 g", "cooked brown rice (80 g per serving)" ],
  [ :pantry, "4 tbsp", "salsa" ],
  [ :fats, "60 g", "avocado (30 g per serving)" ],
  [ :produce, nil, "lime and cilantro" ]
], <<~STEPS
  1. Sauté zucchini, pepper, onion in oil with spices, 8–10 min until tender.
  2. Warm beans in the pan last 2 min.
  3. Serve over rice. Top with salsa, avocado, lime, cilantro.
  4. Tip: blend half the beans into salsa for a smoother sauce if you don't love whole beans.
STEPS

seed_recipe "ginger-soy-stir-fry", {
  name: "Ginger soy stir-fry",
  meal_type: :dinner,
  regular_meal: true,
  prep_time: "20 min",
  serves: 2,
  protein_g: 25,
  calories: 480,
  position: 1,
  description: "Dinner template 2 — Mon default in your weekly rhythm."
}, [
  [ :protein, "300 g", "firm tofu, cubed", "Tofu", 300 ],
  [ :produce, "400 g", "frozen stir-fry vegetables" ],
  [ :fats, "1 tbsp", "sesame or olive oil" ],
  [ :pantry, "2 cloves", "garlic, minced" ],
  [ :pantry, "1 tsp", "fresh ginger, grated" ],
  [ :pantry, "3 tbsp", "soy sauce" ],
  [ :pantry, "1 tbsp", "rice vinegar" ],
  [ :carbs, "160 g", "cooked rice or rice noodles (80 g per serving)" ]
], <<~STEPS
  1. Pan-fry tofu in oil until golden on 2 sides. Remove.
  2. Cook frozen veg 5–6 min. Add garlic and ginger 1 min.
  3. Return tofu. Add soy sauce and vinegar. Toss 2 min.
  4. Serve over measured rice/noodles.
STEPS

seed_recipe "red-lentil-soup", {
  name: "Red lentil soup + side salad",
  meal_type: :dinner,
  regular_meal: true,
  prep_time: "35 min",
  serves: 4,
  protein_g: 18,
  calories: 400,
  position: 2,
  description: "Dinner template 3 — Thu soup night. Freeze 2 portions."
}, [
  [ :fats, "1 tbsp", "olive oil" ],
  [ :produce, "1", "onion, diced" ],
  [ :produce, "2", "carrots, diced" ],
  [ :produce, "2", "celery stalks, diced (optional)" ],
  [ :pantry, "3 cloves", "garlic, minced" ],
  [ :protein, "200 g", "red lentils, rinsed" ],
  [ :pantry, "1 L", "vegetable broth" ],
  [ :pantry, "1 tsp", "cumin" ],
  [ :pantry, "½ tsp", "smoked paprika" ],
  [ :produce, nil, "half-portion power salad (no quinoa) on the side" ],
  [ :carbs, "1 slice", "wholegrain bread + 1 tsp vegan butter" ]
], <<~STEPS
  1. Sauté onion, carrot, celery in oil 5 min. Add garlic 1 min.
  2. Add lentils, broth, spices. Simmer 20–25 min until lentils break down.
  3. Blend partially for creamier texture. Finish with lemon.
  4. Ladle 2 cups soup + small salad + 1 slice bread = one dinner.
STEPS

# --- Snacks ---

seed_recipe "pb-apple-snack", {
  name: "Koro PB + apple",
  meal_type: :snack,
  regular_meal: true,
  prep_time: "1 min",
  serves: 1,
  position: 0,
  description: "Pre-portioned snack — weigh PB, never eat from the jar."
}, [
  [ :produce, "1 medium", "apple", nil, nil ],
  [ :fats, "15 g", "Koro peanut butter", "Purée de cacahuètes", 15 ]
], <<~STEPS
  1. Slice apple. Weigh 15 g peanut butter. Done.
STEPS

seed_recipe "banana-pb-skyr-snack", {
  name: "Banana + PB + Skyr",
  meal_type: :snack,
  regular_meal: true,
  meal_template_slug: "banana-pb-skyr-snack",
  prep_time: "2 min",
  serves: 1,
  position: 1,
  description: "Quick snack — slice one banana, dip in PB and Skyr. Macros from your saved products."
}, [
  [ :produce, "1 whole", "banana, sliced", "Banana", 118 ],
  [ :fats, "1 large tsp", "Koro peanut butter", "Purée de cacahuètes", 8 ],
  [ :protein, "1 tbsp", "Sojasun Skyr nature (plain)", "Skyr vegan", 15 ]
], <<~STEPS
  1. Slice one whole banana onto a plate.
  2. Add 1 large teaspoon Koro peanut butter and 1 tablespoon plain Sojasun Skyr.
  3. Dip slices or spread — log with one tap on your daily log.
STEPS

# --- Suggested (not daily default) ---

seed_recipe "tempeh-salad-option", {
  name: "Pan-glazed tempeh (salad swap)",
  meal_type: :prep,
  regular_meal: false,
  prep_time: "15 min",
  serves: 2,
  protein_g: 20,
  position: 10,
  description: "Swap for tofu in power salad — 100 g per serving."
}, [
  [ :protein, "200 g", "tempeh, thin slices" ],
  [ :pantry, "1 tbsp", "soy sauce" ],
  [ :pantry, "1 tbsp", "maple syrup or agave" ],
  [ :pantry, "1 tsp", "rice vinegar" ],
  [ :fats, "1 tsp", "oil" ]
], <<~STEPS
  1. Steam tempeh 5 min (optional — reduces bitterness).
  2. Pan-fry in oil 2 min/side. Add soy, maple, vinegar; glaze 1 min.
  3. Use 100 g per salad instead of tofu.
STEPS

seed_recipe "black-bean-tacos", {
  name: "Friday fun: black bean tacos",
  meal_type: :dinner,
  regular_meal: false,
  prep_time: "25 min",
  serves: 2,
  calories: 550,
  position: 11,
  description: "Friday fun meal at home — 2 tacos each + big side salad, 1 plate rule."
}, [
  [ :carbs, "4 small", "corn tortillas" ],
  [ :protein, "240 g", "black beans, rinsed, warmed with cumin + garlic" ],
  [ :produce, "1", "pepper + 1 onion, sautéed" ],
  [ :produce, nil, "shredded cabbage, salsa, lime" ],
  [ :produce, nil, "large side salad with 1 tbsp dressing only" ]
], <<~STEPS
  1. Warm tortillas. Fill each with 2 tbsp beans + veg — aim for 2 tacos each.
  2. Eat salad on the side. Wait 15 min before considering seconds.
STEPS

seed_recipe "tofu-scramble", {
  name: "Tofu scramble breakfast",
  meal_type: :breakfast,
  regular_meal: false,
  prep_time: "10 min",
  serves: 1,
  protein_g: 18,
  calories: 350,
  position: 12,
  description: "Alternative breakfast if you get bored of yogurt/oats."
}, [
  [ :protein, "150 g", "firm tofu, crumbled", "Tofu", 150 ],
  [ :fats, "1 tsp", "olive oil" ],
  [ :pantry, "2 tbsp", "nutritional yeast (optional)" ],
  [ :pantry, "½ tsp", "turmeric, salt, pepper, garlic powder" ],
  [ :carbs, "1 slice", "wholegrain toast" ]
], <<~STEPS
  1. Heat oil in a non-stick pan. Add crumbled tofu and spices.
  2. Cook 5–7 min, stirring, until dry and lightly golden.
  3. Serve with toast.
STEPS

seed_recipe "noracooks-vegan-pancakes", {
  name: "Nora Cooks vegan pancakes",
  meal_type: :dinner,
  regular_meal: false,
  meal_template_slug: "noracooks-vegan-pancakes",
  prep_time: "10 min",
  serves: 1,
  position: 13,
  water_suggestion_ml: 250,
  description: "Nora Cooks base batch — we make the smallest amount and split between two. Log YOUR share: Servings = how many pancakes you ate (e.g. 7). Add skyr & strawberries in extras.",
  personal_notes: "Smallest batch shared with husband — I count my pancakes only (e.g. 7 tonight). Top with Sojasun Skyr and strawberries. Source: noracooks.com/vegan-pancakes"
}, [
  [ :carbs, "23.5 g", "all-purpose flour (per pancake)", "All-purpose flour", 23.5 ],
  [ :pantry, "30 ml", "soy milk (per pancake)", "Soja sans sucre", 30 ],
  [ :pantry, "19 ml", "water (per pancake)", nil, nil ],
  [ :fats, "3.5 g", "oil in batter (per pancake)", "Puget Huile d'olive vierge extra", 3.5 ],
  [ :pantry, "⅛ tsp", "baking powder, pinch salt, ~3 g sugar (per pancake)", nil, nil ],
  [ :protein, "optional", "Sojasun Skyr topping (add in extras when logging)", nil, nil ],
  [ :produce, "several small", "strawberries (add in extras when logging)", nil, nil ]
], <<~STEPS
  From Nora Cooks (noracooks.com/vegan-pancakes). We make one base batch and share it — don't use Nora's “serves 3” for logging.

  1. Whisk 1½ cups flour, 1 tbsp baking powder, ½ tsp salt, 2 tbsp sugar.
  2. Stir in 1 cup soy milk, ½ cup water, 2 tbsp oil until just combined (lumps OK).
  3. Heat griddle over medium-high. Grease pan, pour ⅓ cup batter per pancake.
  4. Cook until bubbles form, flip, cook ~1 min until golden. Split the stack between us.

  To log your meal: Servings = pancakes you ate (e.g. 7) → add skyr (tbsp) and strawberries (g) in extras → Log this meal today.
STEPS

seed_recipe "noracooks-oil-free-walnut-brownies", {
  name: "Nora Cooks oil-free walnut brownies (cupcakes)",
  meal_type: :snack,
  regular_meal: false,
  meal_template_slug: "noracooks-oil-free-walnut-brownies",
  prep_time: "55 min",
  serves: 1,
  position: 14,
  water_suggestion_ml: 250,
  description: "Nora Cooks Best Ever Vegan Brownies, oil-free (applesauce for butter), " \
               "chia instead of flax, walnuts, no chocolate chips. " \
               "Baked as 15 cupcakes in ⅛-cup molds. Log servings = cupcakes eaten. " \
               "Source: noracooks.com/vegan-brownies-recipe",
  personal_notes: "As made: chia eggs (not flax), no chocolate chips, ⅛-cup cupcake molds → 15."
}, [
  [ :pantry, "4 g", "chia (per cupcake)", "Chia seeds", 4.0 ],
  [ :pantry, "8.1 g", "unsweetened applesauce (per cupcake)", "Unsweetened applesauce", 8.133 ],
  [ :pantry, "13.3 g", "granulated sugar (per cupcake)", "Granulated sugar", 13.333 ],
  [ :pantry, "14.7 g", "brown sugar (per cupcake)", "Brown sugar", 14.667 ],
  [ :carbs, "8.3 g", "flour (per cupcake)", "All-purpose flour", 8.333 ],
  [ :pantry, "5.7 g", "cocoa (per cupcake)", "Unsweetened cocoa powder", 5.733 ],
  [ :fats, "5 g", "walnuts (per cupcake)", "Walnuts", 5.0 ],
  [ :pantry, nil, "vanilla, salt, baking powder (batch)", nil, nil ]
], <<~STEPS
  Nora Cooks oil-free brownies — as made (chia, no chips, cupcake molds).

  Batch (15 cupcakes, ⅛-cup molds):
  1. Chia eggs: 4 tbsp chia seeds + ½ cup water; thicken.
  2. Oven 175°C / 350°F. Line or grease ⅛-cup cupcake molds.
  3. Whisk ½ cup unsweetened applesauce with 1 cup sugar + 1 cup packed brown sugar.
     Add chia eggs + 1 tbsp vanilla.
  4. Sift in 1 cup flour + 1 cup unsweetened cocoa; add ½ tsp salt + 1 tsp baking powder.
     Stir until just combined.
  5. Fold in ¾ cup chopped walnuts only (no chocolate chips).
  6. Fill molds; bake until set (check earlier than a full pan — start around 18–25 min).
     Cool before removing.

  To log: Servings = cupcakes you ate (e.g. 3).
STEPS

seed_recipe "roasted-sweet-yellow-potatoes", {
  name: "Roasted sweet + yellow potatoes (batch)",
  meal_type: :prep,
  regular_meal: true,
  meal_template_slug: "roasted-sweet-yellow-potatoes",
  prep_time: "45 min",
  serves: 1,
  position: 20,
  water_suggestion_ml: 250,
  description: "Full tray: 1 sweet potato + 4 yellow potatoes, roasted with oil. " \
               "Log a plate share in Build a meal (¼, ½…) alone or with zucchini + tofu."
}, [
  [ :carbs, "200 g", "1 whole sweet potato", "Sweet potato", 200 ],
  [ :carbs, "600 g", "4 yellow potatoes", "Yellow potato", 600 ],
  [ :fats, "10 g", "1 tbsp olive oil", "Puget Huile d'olive vierge extra", 10 ]
], <<~STEPS
  1. Cut 1 medium sweet potato (~200 g) and 4 medium/small yellow potatoes (~600 g) into triangles.
  2. Toss with ~1 tbsp olive oil and seasoning.
  3. Roast until browned and tender.
  4. In Build a meal, pick this batch and enter how much of the tray you ate (½, ¼…).
STEPS

seed_recipe "zucchini-tofu-batch", {
  name: "Zucchini + tofu (batch)",
  meal_type: :prep,
  regular_meal: true,
  meal_template_slug: "zucchini-tofu-batch",
  prep_time: "30 min",
  serves: 1,
  position: 21,
  water_suggestion_ml: 250,
  description: "Yellow + green zucchini with tofu. Mix leftovers with roasted potatoes in Build a meal."
}, [
  [ :produce, "400 g", "yellow + green zucchini", "Zucchini", 400 ],
  [ :protein, "300 g", "tofu cubes", "Tofu", 300 ],
  [ :fats, "10 g", "1 tbsp olive oil", "Puget Huile d'olive vierge extra", 10 ]
], <<~STEPS
  1. Slice ~400 g yellow + green zucchini; cube ~300 g tofu.
  2. Toss with oil and seasoning; roast or sauté until tender.
  3. Store. Log a tray share in Build a meal (alone or with roasted potatoes).
STEPS

seed_recipe "ethiquete-bowl", {
  name: "L'Éthiquête bowl du moment",
  meal_type: :lunch,
  regular_meal: false,
  meal_template_slug: "ethiquete-bowl",
  serves: 1,
  position: 30,
  description: "Nantes restaurant bowl estimate. ~850 kcal full."
}, [
  [ :carbs, "500 g", "1 full bowl", "L'Éthiquête bowl du moment (pasta)", 500 ]
], "Order the bowl. Log 1× full, or scale if shared."

seed_recipe "ethiquete-houmous", {
  name: "L'Éthiquête houmous",
  meal_type: :snack,
  regular_meal: false,
  meal_template_slug: "ethiquete-houmous",
  serves: 1,
  position: 31,
  description: "Shared houmous side. Full plate ≈ ½ cup (~120 g)."
}, [
  [ :protein, "120 g", "½ cup plate", "L'Éthiquête houmous (side)", 120 ]
], "Log 1× for the whole side, 0.5× when shared."

seed_recipe "ethiquete-fondant", {
  name: "L'Éthiquête fondant au chocolat",
  meal_type: :snack,
  regular_meal: false,
  meal_template_slug: "ethiquete-fondant",
  serves: 1,
  position: 32,
  description: "Vegan chocolate fondant estimate (~370 kcal full)."
}, [
  [ :pantry, "100 g", "1 portion", "L'Éthiquête fondant au chocolat", 100 ]
], "Log 1× full, 0.5× when shared."

# Retire the legacy placeholder. Archive rather than destroy so existing links
# and bookmarks keep resolving instead of 404ing.
Recipe.find_by(slug: "lighter-pancakes")&.update!(status: :archived)

puts "Recipes loaded — #{Recipe.count} recipes, #{RecipeIngredient.count} ingredients."
end # unless $RECIPES_SEED_HELPER_ONLY
