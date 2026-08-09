# frozen_string_literal: true

class MealEntryNutritionBuilder
  def initialize(entry, recipe: nil, servings: 1, extras: {}, ingredients: {})
    @entry = entry
    @recipe = recipe
    @servings = [ servings.to_i, 1 ].max
    @extras = normalize_params(extras)
    @ingredient_overrides = normalize_ingredients(ingredients)
  end

  def apply!
    if @recipe
      apply_from_recipe_base!
    elsif @servings > 1
      scale_entry!(@servings)
    end

    apply_extras!
    @entry
  end

  private

  # Extras and ingredients arrive from the form as ActionController::Parameters,
  # which is not a Hash — treating it as one silently dropped every row. Scripts
  # and specs pass plain hashes with symbol keys, so settle on string keys and
  # read them one way everywhere.
  def normalize_params(value)
    case value
    when ActionController::Parameters then value.permit!.to_h
    when Hash then value.stringify_keys
    else {}
    end
  end

  # Rows look like { "12" => { "grams" => "90", "include" => "1" } }. An
  # unchecked row means the ingredient was left out, which is zero grams rather
  # than "use the recipe default".
  def normalize_ingredients(value)
    normalize_params(value).each_with_object({}) do |(id, row), result|
      row = normalize_params(row)
      next if row.blank?

      included = row["include"].to_s != "0"
      grams = row["grams"].to_s.strip

      result[id.to_s] = if included
        next if grams.blank?
        grams.to_d
      else
        0.to_d
      end
    end
  end

  def apply_from_recipe_base!
    per = nutrition_per_serving
    @entry.assign_attributes(
      calories: (per[:calories] * @servings).round,
      protein_g: (per[:protein] * @servings).round(1),
      carbs_g: (per[:carbs] * @servings).round(1),
      fat_g: (per[:fat] * @servings).round(1)
    )
    @entry.ingredient_overrides = @ingredient_overrides.transform_values(&:to_f)
  end

  # Falls back to the recipe's own figures when nothing was adjusted, so an
  # untouched recipe logs exactly as it always did.
  def nutrition_per_serving
    return @recipe.nutrition_per_serving if @ingredient_overrides.empty?

    totals = { calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0 }

    @recipe.recipe_ingredients.each do |ingredient|
      product = ingredient.product
      next unless product

      grams = @ingredient_overrides.fetch(ingredient.id.to_s, ingredient.quantity_g)
      next unless grams.to_f.positive?

      nutrition = product.nutrition_for(grams)
      totals[:calories] += nutrition[:calories]
      totals[:protein] += nutrition[:protein]
      totals[:carbs] += nutrition[:carbs]
      totals[:fat] += nutrition[:fat]
    end

    divisor = @recipe.serves.to_i.positive? ? @recipe.serves : 1
    {
      calories: (totals[:calories].to_f / divisor).round,
      protein: (totals[:protein] / divisor).round(1),
      carbs: (totals[:carbs] / divisor).round(1),
      fat: (totals[:fat] / divisor).round(1)
    }
  end

  def scale_entry!(factor)
    @entry.assign_attributes(
      calories: (@entry.calories * factor).round,
      protein_g: (@entry.protein_g * factor).round(1),
      carbs_g: (@entry.carbs_g.to_f * factor).round(1),
      fat_g: (@entry.fat_g.to_f * factor).round(1)
    )
  end

  def apply_extras!
    extra_notes = []

    @extras.each_value do |extra|
      extra = normalize_params(extra)
      product_id = extra["product_id"].presence
      next if product_id.blank?

      product = Product.find_by(id: product_id)
      next unless product

      grams = grams_for_extra(product, extra)
      next unless grams.positive?

      nutrition = product.nutrition_for(grams)
      @entry.calories += nutrition[:calories]
      @entry.protein_g += nutrition[:protein]
      @entry.carbs_g = @entry.carbs_g.to_f + nutrition[:carbs]
      @entry.fat_g = @entry.fat_g.to_f + nutrition[:fat]

      extra_notes << extra_label(product, extra, grams)
    end

    return if extra_notes.empty?

    combined = [ @entry.notes, extra_notes.join("; ") ].compact_blank.join(" · ")
    @entry.notes = combined
  end

  def grams_for_extra(product, extra)
    quantity = extra["quantity"].to_s.to_d
    return 0 unless quantity.positive?

    unit = extra["unit"].presence || "g"
    return quantity if unit == "g"

    serving = product.default_serving_g.to_d
    serving = 15 if serving.zero?
    quantity * serving
  end

  def extra_label(product, extra, grams)
    quantity = extra["quantity"].to_s
    unit = extra["unit"].presence || "g"

    if unit == "g"
      "+ #{grams.to_i} g #{product.name}"
    else
      "+ #{quantity} #{unit} #{product.name}"
    end
  end
end
