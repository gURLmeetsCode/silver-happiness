class Product < ApplicationRecord
  has_many :meal_template_items, dependent: :restrict_with_error
  has_many :recipe_ingredients, dependent: :nullify

  validates :name, presence: true
  validates :calories_per_100g, :protein_per_100g, presence: true
  validates :default_serving_g, presence: true, numericality: { greater_than: 0 }, if: :quick_log?
  validates :water_volume_ml, numericality: { greater_than: 0 }, allow_nil: true
  validate :water_volume_only_for_beverages

  scope :quick_log, -> { where(quick_log: true).order(:name) }
  scope :quick_log_beverages, -> { quick_log.where(beverage: true) }
  scope :quick_log_snacks, -> { quick_log.where(beverage: false) }

  def beverage?
    beverage
  end

  def quick_log_meal_type
    beverage? ? :beverage : :snack
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

  def quick_log_label
    nutrition = nutrition_for(default_quantity_g)
    parts = [ name ]
    parts << serving_label if serving_label.present?
    label = "#{parts.join(' · ')} (#{nutrition[:calories]} kcal)"
    label += " · +#{water_volume_ml} ml water" if water_volume_ml.to_i.positive?
    label
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
