class MealEntry < ApplicationRecord
  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2, snack: 3, beverage: 4 }, prefix: true

  belongs_to :daily_log
  belongs_to :meal_template, optional: true
  has_many :items, -> { in_order }, class_name: "MealEntryItem", dependent: :destroy, inverse_of: :meal_entry

  # Per-ingredient amounts chosen when logging a recipe, keyed by
  # recipe_ingredient id: { "12" => 90.0 }. Zero means "left out". Stored so
  # reopening the meal shows the wrap you actually ate rather than resetting to
  # the recipe's defaults.
  serialize :ingredient_overrides, coder: JSON, type: Hash

  validates :name, presence: true
  validates :calories, :protein_g, numericality: { greater_than_or_equal_to: 0 }
  validates :water_suggestion_ml, numericality: { greater_than: 0 }, allow_nil: true

  before_destroy :refund_logged_water

  def water_logged?
    water_logged_ml.to_i.positive?
  end

  # Replaces whatever this meal was made of. Amounts are summed per product so a
  # recipe that uses oil twice is one line rather than two.
  def record_items!(rows)
    totals = rows.each_with_object({}) do |row, sums|
      product_id = row[:product_id] || row[:product]&.id
      grams = row[:grams].to_f
      next unless product_id && grams.positive?

      sums[product_id] = sums.fetch(product_id, 0) + grams
    end

    items.destroy_all if persisted?
    totals.each_with_index do |(product_id, grams), index|
      items.build(product_id: product_id, grams: grams.round(2), position: index)
    end
  end

  # Grams chosen for this ingredient, or nil when it was never adjusted.
  def override_for(recipe_ingredient)
    return nil if ingredient_overrides.blank?

    ingredient_overrides[recipe_ingredient.id.to_s]&.to_d
  end

  def water_cups_label
    cups = (water_suggestion_ml / 250.0).round(1)
    cups == 1 ? "1 cup" : "#{cups} cups"
  end

  def water_prompt
    return nil if meal_type_beverage?

    "Drink #{water_cups_label} (#{water_suggestion_ml} ml) with this meal"
  end

  def shows_meal_water_actions?
    !meal_type_beverage? && water_suggestion_ml.to_i.positive?
  end

  def log_water_with_meal!
    return false if water_logged?

    transaction do
      update!(water_logged_ml: water_suggestion_ml)
      daily_log.add_water!(water_suggestion_ml)
    end
    true
  end

  private

  def refund_logged_water
    return unless water_logged?

    daily_log.update!(water_ml: [ daily_log.water_ml - water_logged_ml, 0 ].max)
  end
end
