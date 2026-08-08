class MealEntry < ApplicationRecord
  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2, snack: 3, beverage: 4 }, prefix: true

  belongs_to :daily_log
  belongs_to :meal_template, optional: true

  validates :name, presence: true
  validates :calories, :protein_g, numericality: { greater_than_or_equal_to: 0 }
  validates :water_suggestion_ml, numericality: { greater_than: 0 }, allow_nil: true

  before_destroy :refund_logged_water

  def water_logged?
    water_logged_ml.to_i.positive?
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
