# frozen_string_literal: true

class MealEntryNutritionBuilder
  def initialize(entry, recipe: nil, servings: 1, extras: {})
    @entry = entry
    @recipe = recipe
    @servings = [ servings.to_i, 1 ].max
    @extras = normalize_extras(extras)
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

  # Extras arrive from the form as ActionController::Parameters, which is not a
  # Hash — treating it as one silently dropped every extra the user added.
  def normalize_extras(extras)
    case extras
    when ActionController::Parameters then extras.permit!.to_h
    when Hash then extras
    else {}
    end
  end

  def apply_from_recipe_base!
    per = @recipe.nutrition_per_serving
    @entry.assign_attributes(
      calories: (per[:calories] * @servings).round,
      protein_g: (per[:protein] * @servings).round(1),
      carbs_g: (per[:carbs] * @servings).round(1),
      fat_g: (per[:fat] * @servings).round(1)
    )
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
      product_id = extra[:product_id].presence || extra["product_id"].presence
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
    quantity = (extra[:quantity].presence || extra["quantity"].presence).to_d
    return 0 unless quantity.positive?

    unit = extra[:unit].presence || extra["unit"].presence || "g"
    return quantity if unit == "g"

    serving = product.default_serving_g.to_d
    serving = 15 if serving.zero?
    quantity * serving
  end

  def extra_label(product, extra, grams)
    quantity = (extra[:quantity].presence || extra["quantity"].presence).to_s
    unit = extra[:unit].presence || extra["unit"].presence || "g"
    if unit == "tbsp"
      tbsp_word = quantity == "1" ? "tbsp" : "tbsp"
      "+ #{quantity} #{tbsp_word} #{product.name}"
    else
      "+ #{grams.to_i} g #{product.name}"
    end
  end
end
