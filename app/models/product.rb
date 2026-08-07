class Product < ApplicationRecord
  has_many :meal_template_items, dependent: :restrict_with_error
  has_many :recipe_ingredients, dependent: :nullify

  validates :name, presence: true

  def nutrition_for(grams)
    factor = grams.to_d / 100
    {
      calories: (calories_per_100g * factor).round,
      protein: (protein_per_100g * factor).round(1),
      carbs: (carbs_per_100g * factor).round(1),
      fat: (fat_per_100g * factor).round(1)
    }
  end
end
