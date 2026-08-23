class Product < ApplicationRecord
  has_many :meal_template_items, dependent: :restrict_with_error
  has_many :recipe_ingredients, dependent: :nullify

  validates :name, presence: true
  validates :calories_per_100g, :protein_per_100g, presence: true
  validates :water_volume_ml, numericality: { greater_than: 0 }, allow_nil: true
  validate :water_volume_only_for_beverages

  def beverage?
    beverage
  end

  def default_quantity_g
    default_serving_g.presence || 100
  end

  def log_name(quantity_g = default_quantity_g)
    qty = quantity_g.to_d
    if serving_label.present?
      "#{name} (#{serving_label})"
    elsif qty != 100
      "#{qty.to_i}g #{name}"
    else
      name
    end
  end

  def suggested_grocery_category
    case name
    when /tofu|skyr|yogurt|protein|bean|lentil|hummus|houmous|chickpea/i then "protein"
    when /oat|quinoa|rice|pasta|bread|flour/i then "carbs"
    when /cacahuète|peanut|oil|avocat|walnut|almond|tahini/i then "fats"
    when /chia|soja|soy|vinegar|sauce|mustard|cocoa|sugar/i then "pantry"
    when /tomato|zucchini|lettuce|spinach|pepper|onion|garlic|fruit|berry/i then "produce"
    else "other"
    end
  end

  ML_PER_UNIT = { "tsp" => 5.0, "tbsp" => 15.0, "cup" => 240.0, "ml" => 1.0 }.freeze

  # Volume units a person actually says out loud, plus this product's own
  # serving ("1 pavé (125 g)") so half a pack is 0.5 rather than 62.5 g.
  def unit_options
    options = []
    options << [ serving_label.presence || "serving", "serving" ] if default_serving_g.to_f.positive?
    options + [ [ "g", "g" ], [ "tsp", "tsp" ], [ "tbsp", "tbsp" ], [ "cup", "cup" ], [ "ml", "ml" ] ]
  end

  # Worked out from the serving label where possible: olive oil described as
  # "1 tbsp (10 g)" is 10 g per 15 ml, so half a teaspoon is 3 g rather than the
  # 5 g a water-density guess would give. Falls back to water.
  def grams_per_ml
    @grams_per_ml ||= begin
      match = serving_label.to_s.match(/(\d+(?:[.,]\d+)?)\s*(tsp|teaspoons?|tbsp|tablespoons?|cups?|ml)\b/i)
      derived = if match && default_serving_g.to_f.positive?
        unit = match[2].downcase.sub(/s$/, "").sub("teaspoon", "tsp").sub("tablespoon", "tbsp")
        millilitres = match[1].tr(",", ".").to_f * ML_PER_UNIT.fetch(unit, 0)
        default_serving_g.to_f / millilitres if millilitres.positive?
      end

      derived&.positive? ? derived : 1.0
    end
  end

  def grams_for(quantity, unit)
    amount = quantity.to_f
    return 0 unless amount.positive?

    case unit.to_s
    when "serving" then amount * default_quantity_g.to_f
    when "g", "" then amount
    else amount * ML_PER_UNIT.fetch(unit.to_s, 1.0) * grams_per_ml
    end
  end

  def nutrition_for(grams)
    factor = grams.to_d / 100
    {
      calories: (calories_per_100g * factor).round,
      protein: (protein_per_100g * factor).round(1),
      carbs: (carbs_per_100g * factor).round(1),
      fat: (fat_per_100g * factor).round(1)
    }
  end

  private

  def water_volume_only_for_beverages
    return if water_volume_ml.blank?
    return if beverage?

    errors.add(:water_volume_ml, "only applies to beverages")
  end
end
