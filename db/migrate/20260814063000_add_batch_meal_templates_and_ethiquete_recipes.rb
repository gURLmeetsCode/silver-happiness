# frozen_string_literal: true

# Makes leftover batches and restaurant favorites reusable:
# - roasted potato tray already existed as a template; link a Recipe for it
# - zucchini + tofu sheet-pan batch (mix with potatoes in Build a meal)
# - L'Éthiquête bowl / houmous / fondant as one-tap templates + recipes
class AddBatchMealTemplatesAndEthiqueteRecipes < ActiveRecord::Migration[8.0]
  ETHIQUETE_PRODUCTS = [
    {
      name: "L'Éthiquête bowl du moment (pasta)",
      brand: "L'Éthiquête Nantes",
      calories_per_100g: 170, protein_per_100g: 8.0, carbs_per_100g: 18.0, fat_per_100g: 6.4,
      default_serving_g: 500, serving_label: "1 bowl (~500 g)",
      notes: "Estimate. Menu pasta bowl: chickpea pasta (GF), veg, beans, seeds, " \
             "vinaigrette, tofu rosso. ~850 kcal / ~40 g protein per bowl."
    },
    {
      name: "L'Éthiquête houmous (side)",
      brand: "L'Éthiquête Nantes",
      calories_per_100g: 270, protein_per_100g: 8.2, carbs_per_100g: 8.0, fat_per_100g: 22.0,
      default_serving_g: 120, serving_label: "½ cup houmous (~120 g, shared plate)",
      notes: "Menu: « Houmous à partager… Ou pas! ». Plate was ~½ cup total (~120 g). " \
             "~270 kcal/100 g (restaurant/CIQUAL oilier range)."
    },
    {
      name: "L'Éthiquête fondant au chocolat",
      brand: "L'Éthiquête Nantes",
      calories_per_100g: 370, protein_per_100g: 5.0, carbs_per_100g: 42.0, fat_per_100g: 20.0,
      default_serving_g: 100, serving_label: "1 portion (~100 g)",
      notes: "Estimate for vegan chocolate fondant / moelleux. ~370 kcal per full portion."
    }
  ].freeze

  def up
    ensure_ethiquete_products!
    ensure_templates!
    ensure_recipes!
  end

  def down
    %w[
      roasted-sweet-yellow-potatoes
      zucchini-tofu-batch
      ethiquete-bowl
      ethiquete-houmous
      ethiquete-fondant
    ].each do |slug|
      Recipe.find_by(slug: slug)&.destroy
      MealTemplate.find_by(slug: slug)&.destroy
    end
  end

  private

  def ensure_ethiquete_products!
    ETHIQUETE_PRODUCTS.each do |attrs|
      product = Product.find_or_initialize_by(name: attrs[:name])
      product.assign_attributes(attrs)
      product.save!
    end
  end

  def ensure_templates!
    zucchini = ensure_product!("Zucchini",
      calories_per_100g: 17, protein_per_100g: 1.2, carbs_per_100g: 3.1, fat_per_100g: 0.3,
      default_serving_g: 100, serving_label: "½ zucchini (~100 g)")
    tofu = ensure_product!("Tofu",
      calories_per_100g: 145, protein_per_100g: 16, carbs_per_100g: 2, fat_per_100g: 8,
      default_serving_g: 125, serving_label: "1 pavé (125 g)")
    oil = Product.find_by(name: "Puget Huile d'olive vierge extra") ||
      ensure_product!("Puget Huile d'olive vierge extra",
        brand: "Puget",
        calories_per_100g: 900, protein_per_100g: 0, carbs_per_100g: 0, fat_per_100g: 100,
        default_serving_g: 10, serving_label: "1 tbsp (10 g)")

    # Full tray: yellow + green zucchini with tofu — scale in Build a meal.
    upsert_template!(
      "zucchini-tofu-batch",
      "Zucchini + tofu (batch)",
      :dinner,
      [
        [ zucchini, 400, "yellow + green zucchini (~400 g)" ],
        [ tofu, 300, "tofu cubes (~300 g / ~2½ pavés)" ],
        [ oil, 10, "1 tbsp olive oil" ]
      ]
    )

    # Roasted potato tray may already exist from seeds; ensure it is present.
    sweet = Product.find_by(name: "Sweet potato")
    yellow = Product.find_by(name: "Yellow potato")
    if sweet && yellow
      upsert_template!(
        "roasted-sweet-yellow-potatoes",
        "Roasted sweet + yellow potatoes (batch)",
        :dinner,
        [
          [ sweet, 200, "1 whole sweet potato (~200 g raw)" ],
          [ yellow, 600, "4 medium/small yellow potatoes (~150 g each, raw)" ],
          [ oil, 10, "1 tbsp Puget olive oil" ]
        ]
      )
    end

    bowl = Product.find_by!(name: "L'Éthiquête bowl du moment (pasta)")
    houmous = Product.find_by!(name: "L'Éthiquête houmous (side)")
    fondant = Product.find_by!(name: "L'Éthiquête fondant au chocolat")

    upsert_template!("ethiquete-bowl", "L'Éthiquête bowl du moment", :lunch, [
      [ bowl, 500, "1 full bowl" ]
    ])
    upsert_template!("ethiquete-houmous", "L'Éthiquête houmous (side)", :snack, [
      [ houmous, 120, "½ cup plate (~120 g)" ]
    ])
    upsert_template!("ethiquete-fondant", "L'Éthiquête fondant au chocolat", :snack, [
      [ fondant, 100, "1 full portion" ]
    ])
  end

  def ensure_recipes!
    if MealTemplate.exists?(slug: "roasted-sweet-yellow-potatoes")
      link_recipe!(
        slug: "roasted-sweet-yellow-potatoes",
        name: "Roasted sweet + yellow potatoes (batch)",
        meal_type: :prep,
        meal_template_slug: "roasted-sweet-yellow-potatoes",
        regular_meal: true,
        description: "Full tray: 1 sweet potato + 4 yellow potatoes, roasted with oil. " \
                     "Log a plate share in Build a meal (¼, ½…) alone or with zucchini + tofu.",
        steps: <<~STEPS.strip
          1. Cut 1 medium sweet potato (~200 g) and 4 medium/small yellow potatoes (~600 g) into triangles.
          2. Toss with ~1 tbsp olive oil and seasoning.
          3. Roast until browned and tender.
          4. Log the full tray as 1× batch, or mix a fraction with other batches in Build a meal.
        STEPS
      )
    end

    link_recipe!(
      slug: "zucchini-tofu-batch",
      name: "Zucchini + tofu (batch)",
      meal_type: :prep,
      meal_template_slug: "zucchini-tofu-batch",
      regular_meal: true,
      description: "Sheet-pan / skillet batch of yellow + green zucchini with tofu. " \
                   "Scale leftovers in Build a meal — e.g. ½ this batch + ¼ roasted potatoes.",
      steps: <<~STEPS.strip
        1. Slice ~400 g yellow + green zucchini; cube ~300 g tofu.
        2. Toss with ~1 tbsp oil and seasoning; roast or sauté until tender and golden.
        3. Cool and store. When eating, pick this batch in Build a meal and enter how much of the tray (½, ¼…).
      STEPS
    )

    link_recipe!(
      slug: "ethiquete-bowl",
      name: "L'Éthiquête bowl du moment",
      meal_type: :lunch,
      meal_template_slug: "ethiquete-bowl",
      regular_meal: false,
      description: "Nantes restaurant bowl estimate (chickpea pasta, veg, beans, seeds, vinaigrette, tofu rosso). ~850 kcal.",
      steps: "Order the bowl du moment. Log 1× for a full bowl, or scale if you share."
    )

    link_recipe!(
      slug: "ethiquete-houmous",
      name: "L'Éthiquête houmous",
      meal_type: :snack,
      meal_template_slug: "ethiquete-houmous",
      regular_meal: false,
      description: "Shared houmous side estimate. Full plate ≈ ½ cup (~120 g). Use 0.5× if you split it.",
      steps: "Log 1× for the whole side plate, 0.5× for a shared half."
    )

    link_recipe!(
      slug: "ethiquete-fondant",
      name: "L'Éthiquête fondant au chocolat",
      meal_type: :snack,
      meal_template_slug: "ethiquete-fondant",
      regular_meal: false,
      description: "Vegan chocolate fondant estimate (~370 kcal full). Use 0.5× when sharing.",
      steps: "Log 1× for a full cake, 0.5× when shared."
    )
  end

  def ensure_product!(name, attrs)
    product = Product.find_or_initialize_by(name: name)
    product.assign_attributes(attrs) if product.new_record?
    product.save!
    product
  end

  def upsert_template!(slug, name, meal_type, items)
    template = MealTemplate.find_or_initialize_by(slug: slug)
    template.assign_attributes(name: name, meal_type: meal_type)
    template.save!
    template.meal_template_items.destroy_all
    items.each do |product, quantity_g, label|
      next unless product

      template.meal_template_items.create!(product: product, quantity_g: quantity_g, label: label)
    end
    template
  end

  def link_recipe!(slug:, name:, meal_type:, meal_template_slug:, regular_meal:, description:, steps:)
    template = MealTemplate.find_by!(slug: meal_template_slug)
    recipe = Recipe.find_or_initialize_by(slug: slug)
    return if recipe.persisted? && recipe.user_created?

    recipe.assign_attributes(
      name: name,
      meal_type: meal_type,
      meal_template: template,
      regular_meal: regular_meal,
      description: description,
      steps: steps,
      serves: 1,
      water_suggestion_ml: 250
    )
    recipe.save!
    recipe.sync_from_meal_template!
    recipe
  end
end
