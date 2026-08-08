class Product < ApplicationRecord
  has_many :meal_template_items, dependent: :restrict_with_error
  has_many :recipe_ingredients, dependent: :nullify

  validates :name, presence: true

  scope :quick_log, -> { where(quick_log: true).order(:name) }

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

  def quick_log_label
    nutrition = nutrition_for(default_quantity_g)
    parts = [ name ]
    parts << serving_label if serving_label.present?
    "#{parts.join(' · ')} (#{nutrition[:calories]} kcal)"
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
end
