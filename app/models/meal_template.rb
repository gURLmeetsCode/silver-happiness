class MealTemplate < ApplicationRecord
  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2, snack: 3 }, prefix: true

  has_many :meal_template_items, dependent: :destroy
  has_many :products, through: :meal_template_items
  has_many :meal_entries, dependent: :nullify
  has_one :recipe, dependent: :nullify

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  def total_calories
    meal_template_items.sum(&:calories)
  end

  def total_protein
    meal_template_items.sum(&:protein_g)
  end

  def total_carbs
    meal_template_items.sum(&:carbs_g)
  end

  def total_fat
    meal_template_items.sum(&:fat_g)
  end

  def summary
    meal_template_items.map(&:display_label).join(" · ")
  end

  def water_cups_label
    cups = (water_suggestion_ml / 250.0).round(1)
    cups == 1 ? "1 cup" : "#{cups} cups"
  end
end
