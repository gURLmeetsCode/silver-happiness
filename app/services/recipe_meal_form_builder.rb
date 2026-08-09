# frozen_string_literal: true

class RecipeMealFormBuilder
  EXTRA_ROWS = 4

  SUGGESTED_PRODUCT_NAMES = [
    "Cholula Chipotle sauce",
    "Jalapeños (pickled)",
    "Zucchini",
    "Puget Huile d'olive vierge extra"
  ].freeze

  SUGGESTED_BY_RECIPE_SLUG = {
    "noracooks-vegan-pancakes" => [ "Skyr vegan", "Strawberries" ]
  }.freeze

  attr_reader :recipe, :entry

  def initialize(recipe, entry: nil)
    @recipe = recipe
    @entry = entry
  end

  def nutrition
    @nutrition ||= recipe.nutrition_per_serving
  end

  def extra_rows
    EXTRA_ROWS
  end

  def suggested_products
    @suggested_products ||= begin
      names = SUGGESTED_PRODUCT_NAMES + (SUGGESTED_BY_RECIPE_SLUG[recipe.slug] || [])
      seeded = names.filter_map { |name| Product.find_by(name: name) }
      from_recipe = recipe.recipe_ingredients.filter_map(&:product)
      (seeded + from_recipe).uniq.first(EXTRA_ROWS)
    end
  end

  def inferred_servings
    return 1 unless entry && nutrition[:calories].to_i.positive?

    [ (entry.calories.to_f / nutrition[:calories]).round, 1 ].max
  end
end
