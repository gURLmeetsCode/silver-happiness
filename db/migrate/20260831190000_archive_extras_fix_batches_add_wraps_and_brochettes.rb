# frozen_string_literal: true

# - Archive unused "Extras & swaps" recipes that were never on rotation
# - Align batch tray tofu grams with Céréal Bio pack labels (125 g pavé / 250 g pack)
# - Add Thai rice-paper wraps + oven veggie brochettes with BBQ bean brush
class ArchiveExtrasFixBatchesAddWrapsAndBrochettes < ActiveRecord::Migration[8.0]
  ARCHIVE_SLUGS = %w[tempeh-salad-option black-bean-tacos tofu-scramble].freeze

  NEW_PRODUCTS = [
    {
      name: "Rice paper wrappers",
      brand: nil,
      calories_per_100g: 333,
      protein_per_100g: 0.5,
      carbs_per_100g: 82.0,
      fat_per_100g: 0.5,
      default_serving_g: 10,
      serving_label: "1 sheet (~10 g dry)",
      notes: "Typical round bánh tráng sheet ~8–12 g dry. Softens in water before rolling."
    },
    {
      name: "Cucumber",
      calories_per_100g: 15,
      protein_per_100g: 0.7,
      carbs_per_100g: 2.5,
      fat_per_100g: 0.1,
      default_serving_g: 100,
      serving_label: "100 g (~⅓ cucumber)",
      notes: "CIQUAL concombre cru."
    },
    {
      name: "Carrot",
      calories_per_100g: 36,
      protein_per_100g: 0.8,
      carbs_per_100g: 6.5,
      fat_per_100g: 0.2,
      default_serving_g: 80,
      serving_label: "1 medium (~80 g)",
      notes: "CIQUAL carotte crue."
    },
    {
      name: "Mushrooms (button)",
      calories_per_100g: 22,
      protein_per_100g: 2.2,
      carbs_per_100g: 2.0,
      fat_per_100g: 0.3,
      default_serving_g: 80,
      serving_label: "~4 medium caps (~80 g)",
      notes: "CIQUAL champignon de Paris cru."
    },
    {
      name: "Soy sauce",
      brand: nil,
      calories_per_100g: 53,
      protein_per_100g: 8.0,
      carbs_per_100g: 4.9,
      fat_per_100g: 0.0,
      default_serving_g: 15,
      serving_label: "1 tbsp (~15 g)",
      notes: "Typical sauce soja. Prefer reduced-salt if you have it."
    },
    {
      name: "Homemade BBQ bean brush",
      brand: nil,
      calories_per_100g: 95,
      protein_per_100g: 3.5,
      carbs_per_100g: 16.0,
      fat_per_100g: 1.5,
      default_serving_g: 30,
      serving_label: "2 tbsp brush (~30 g)",
      notes: "Estimate for blended white/black beans + tomato + vinegar + smoked paprika + maple. " \
             "Brush on oven brochettes — not a bottled BBQ."
    }
  ].freeze

  # One wrap = logging unit. Batch of 4 wraps uses 1 tofu pavé (125 g).
  THAI_WRAP_PER = {
    "Rice paper wrappers" => 10,
    "Tofu" => 31,           # 125 g / 4
    "Cucumber" => 40,
    "Carrot" => 30,
    "Red pepper" => 30,
    "Soy sauce" => 8        # dip share (~½ tbsp)
  }.freeze

  # One brochette skewer = logging unit. Batch of 6 skewers ≈ 1 pack tofu (250 g) + veg.
  BROCHETTE_PER = {
    "Tofu" => 42,                    # 250 g / 6
    "Mushrooms (button)" => 40,
    "Red pepper" => 35,
    "Onion" => 25,
    "Zucchini" => 40,
    "Homemade BBQ bean brush" => 20, # brush per skewer
    "Puget Huile d'olive vierge extra" => 3
  }.freeze

  def up
    archive_unused_extras!
    fix_batch_label_sizes!
    ensure_products!
    ensure_thai_wraps!
    ensure_brochettes!
  end

  def down
    %w[thai-vegan-wraps oven-veggie-brochettes].each do |slug|
      Recipe.find_by(slug: slug)&.destroy
      MealTemplate.find_by(slug: slug)&.destroy
    end
    ARCHIVE_SLUGS.each do |slug|
      Recipe.find_by(slug: slug)&.update!(status: :active)
    end
  end

  private

  def archive_unused_extras!
    ARCHIVE_SLUGS.each do |slug|
      Recipe.find_by(slug: slug)&.update!(status: :archived)
    end
  end

  def fix_batch_label_sizes!
    # Céréal Bio tofu nature: 125 g pavé, 250 g pack = 2 pavés.
    fix_template_item!("zucchini-tofu-batch", "Tofu", 250, "2 pavés / 1 pack (~250 g)")
    fix_recipe_ingredient!("zucchini-tofu-batch", "Tofu", 250, "2 pavés / 1 pack (250 g)")

    fix_template_item!("baked-tofu", "Tofu", 500, "4 pavés / 2 packs (~500 g)") if MealTemplate.exists?(slug: "baked-tofu")
    # baked-tofu may only live as recipe ingredients
    fix_recipe_ingredient!("baked-tofu", "Tofu", 500, "firm tofu, 4 pavés (500 g)")
    Recipe.find_by(slug: "baked-tofu")&.update!(
      description: "Make once, use in power salads and stir-fries. " \
                   "Batch = 2× 250 g packs (4 pavés). Weigh 1 pavé (125 g) per salad.",
      steps: <<~STEPS.strip
        1. Heat oven to 200°C. Line a baking tray.
        2. Toss 500 g tofu (4 pavés) with oil, soy sauce, and spices.
        3. Spread in a single layer. Bake 25–30 min, flip once, until golden.
        4. Store fridge up to 4 days. Weigh 125 g (1 pavé) per salad.
      STEPS
    )

    Recipe.find_by(slug: "zucchini-tofu-batch")&.update!(
      description: "Yellow + green zucchini with 1 pack tofu (2 pavés / 250 g). " \
                   "Log a tray share in Build a meal (¼, ½…).",
      steps: <<~STEPS.strip
        1. Slice ~400 g zucchini; cube 250 g tofu (1× 250 g pack / 2 pavés).
        2. Toss with ~1 tbsp oil and seasoning; roast or sauté until tender.
        3. Store. Log a tray share in Build a meal (alone or with roasted potatoes).
      STEPS
    )

    # Potato tray already matches label servings (200 g sweet + 4× 150 g yellow).
    Recipe.find_by(slug: "roasted-sweet-yellow-potatoes")&.update!(
      description: "Full tray: 1 sweet potato (~200 g label size) + 4 yellow potatoes (~150 g each). " \
                   "Log a plate share in Build a meal (¼, ½…) alone or with zucchini + tofu."
    )
  end

  def fix_template_item!(slug, product_name, grams, label)
    template = MealTemplate.find_by(slug: slug)
    return unless template

    product = Product.find_by(name: product_name)
    return unless product

    item = template.meal_template_items.find_by(product_id: product.id)
    item&.update!(quantity_g: grams, label: label)
  end

  def fix_recipe_ingredient!(slug, product_name, grams, name)
    recipe = Recipe.find_by(slug: slug)
    return unless recipe

    product = Product.find_by(name: product_name)
    return unless product

    ingredient = recipe.recipe_ingredients.find_by(product_id: product.id)
    return unless ingredient

    ingredient.update!(quantity_g: grams, name: name, amount: "#{grams.to_i} g")
    recipe.sync_macros_from_ingredients!
  end

  def ensure_products!
    NEW_PRODUCTS.each do |attrs|
      product = Product.find_or_initialize_by(name: attrs[:name])
      product.assign_attributes(attrs)
      product.save!
    end

    Product.find_by(name: "Tofu") ||
      Product.create!(
        name: "Tofu",
        calories_per_100g: 145, protein_per_100g: 14, carbs_per_100g: 2, fat_per_100g: 8,
        default_serving_g: 125, serving_label: "1 pavé (125 g)"
      )

    Product.find_by(name: "Red pepper") ||
      Product.create!(
        name: "Red pepper",
        calories_per_100g: 31, protein_per_100g: 1, carbs_per_100g: 6, fat_per_100g: 0.3,
        default_serving_g: 80, serving_label: "1 pepper"
      )

    Product.find_by(name: "Onion") ||
      Product.create!(
        name: "Onion",
        calories_per_100g: 39, protein_per_100g: 1.1, carbs_per_100g: 7, fat_per_100g: 0.1,
        default_serving_g: 150, serving_label: "1 medium"
      )

    Product.find_by(name: "Zucchini") ||
      Product.create!(
        name: "Zucchini",
        calories_per_100g: 17, protein_per_100g: 1.2, carbs_per_100g: 3.1, fat_per_100g: 0.3,
        default_serving_g: 100, serving_label: "½ zucchini (~100 g)"
      )

    oil = Product.find_by(name: "Puget Huile d'olive vierge extra")
    unless oil
      Product.create!(
        name: "Puget Huile d'olive vierge extra",
        brand: "Puget",
        calories_per_100g: 900, protein_per_100g: 0, carbs_per_100g: 0, fat_per_100g: 100,
        default_serving_g: 10, serving_label: "1 tbsp (10 g)"
      )
    end
  end

  def ensure_thai_wraps!
    upsert_tracked_recipe!(
      slug: "thai-vegan-wraps",
      name: "Thai vegan rice-paper wraps",
      meal_type: :lunch,
      regular_meal: true,
      position: 23,
      prep_time: "25 min",
      water_suggestion_ml: 250,
      description: "Fresh bánh tráng rolls: tofu, cucumber, carrot, pepper. " \
                   "Soy-sauce dip (no peanut butter). Log servings = wraps you ate. Batch of 4 uses 1 tofu pavé.",
      personal_notes: "Dip is soy-based — not satay/peanut.",
      per_serving: THAI_WRAP_PER,
      labels: {
        "Rice paper wrappers" => "1 sheet (~10 g)",
        "Tofu" => "31 g tofu (1/4 pavé)",
        "Cucumber" => "40 g cucumber",
        "Carrot" => "30 g carrot",
        "Red pepper" => "30 g red pepper",
        "Soy sauce" => "~½ tbsp soy dip"
      },
      steps: <<~STEPS.strip
        Batch (4 wraps — 1 pavé tofu):
        1. Cube or strip 125 g tofu; pan-sear lightly with a splash of soy if you like.
        2. Julienne cucumber, carrot, and red pepper.
        3. Dip each rice paper in warm water until pliable. Fill with tofu + veg; roll tight.
        4. Dip: soy sauce + rice vinegar (or lime) + a little maple + chili flakes / garlic — no peanut butter.
        5. Log servings = how many wraps you ate (e.g. 2).
      STEPS
    )
  end

  def ensure_brochettes!
    upsert_tracked_recipe!(
      slug: "oven-veggie-brochettes",
      name: "Oven veggie brochettes (BBQ bean brush)",
      meal_type: :dinner,
      regular_meal: true,
      position: 24,
      prep_time: "40 min",
      water_suggestion_ml: 300,
      description: "Baked skewers: tofu, mushroom caps, pepper, onion, zucchini. " \
                   "Brush with homemade BBQ bean sauce. Log servings = skewers you ate. Batch of 6 ≈ 1 tofu pack.",
      personal_notes: "Oven-baked brochettes (not grill-only). Sauce is bean-based BBQ brush.",
      per_serving: BROCHETTE_PER,
      labels: {
        "Tofu" => "42 g tofu (1/6 pack)",
        "Mushrooms (button)" => "~2 caps (~40 g)",
        "Red pepper" => "35 g pepper",
        "Onion" => "25 g onion",
        "Zucchini" => "40 g zucchini",
        "Homemade BBQ bean brush" => "~1½ tbsp brush",
        "Puget Huile d'olive vierge extra" => "light oil"
      },
      steps: <<~STEPS.strip
        Batch (6 brochettes — 1× 250 g tofu pack):
        1. Heat oven to 200°C. Soak wooden skewers if using.
        2. Cubes: 250 g tofu, mushroom caps, pepper, onion, zucchini. Light oil + salt/pepper.
        3. Thread onto skewers. Brush with homemade BBQ bean sauce (blend cooked white/black beans with
           tomato purée, vinegar, smoked paprika, maple, garlic, soy — thin with water).
        4. Bake 20–25 min on a tray, turn once, brush again halfway until edges brown.
        5. Log servings = skewers you ate (e.g. 2 or 3).
      STEPS
    )
  end

  def upsert_tracked_recipe!(slug:, name:, meal_type:, regular_meal:, position:, prep_time:,
                             water_suggestion_ml:, description:, personal_notes:, per_serving:, labels:, steps:)
    template = MealTemplate.find_or_initialize_by(slug: slug)
    template.assign_attributes(name: name, meal_type: meal_type == :prep ? :dinner : meal_type)
    template.save!
    template.meal_template_items.destroy_all

    per_serving.each do |product_name, grams|
      product = Product.find_by!(name: product_name)
      template.meal_template_items.create!(
        product: product,
        quantity_g: grams,
        label: labels[product_name] || "#{grams} g"
      )
    end

    recipe = Recipe.find_or_initialize_by(slug: slug)
    return if recipe.persisted? && recipe.user_created?

    recipe.assign_attributes(
      name: name,
      meal_type: meal_type,
      meal_template: template,
      regular_meal: regular_meal,
      serves: 1,
      position: position,
      prep_time: prep_time,
      water_suggestion_ml: water_suggestion_ml,
      description: description,
      personal_notes: personal_notes,
      steps: steps,
      status: :active
    )
    recipe.save!
    recipe.sync_from_meal_template!
  end
end
