class MealTemplateItem < ApplicationRecord
  belongs_to :meal_template
  belongs_to :product

  validates :quantity_g, numericality: { greater_than: 0 }

  def nutrition
    product.nutrition_for(quantity_g)
  end

  def calories
    nutrition[:calories]
  end

  def protein_g
    nutrition[:protein]
  end

  def carbs_g
    nutrition[:carbs]
  end

  def fat_g
    nutrition[:fat]
  end

  def display_label
    label.presence || "#{quantity_g.to_i}g #{product.name}"
  end
end
