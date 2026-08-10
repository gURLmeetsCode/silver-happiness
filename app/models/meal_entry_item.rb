# frozen_string_literal: true

# What a meal was actually made of. Kept so advice about cutting back can name
# the thing you ate and the amount, rather than guessing from the meal's name.
class MealEntryItem < ApplicationRecord
  belongs_to :meal_entry
  belongs_to :product

  validates :grams, numericality: { greater_than: 0 }

  scope :in_order, -> { order(:position, :id) }

  def nutrition
    @nutrition ||= product.nutrition_for(grams)
  end

  def calories
    nutrition[:calories]
  end

  def protein_g
    nutrition[:protein]
  end

  # How much of this item's energy is protein. Oil is 0, tofu is high; used to
  # avoid suggesting you cut back on the things keeping protein up.
  def protein_share
    return 0.0 unless calories.positive?

    (protein_g.to_f * 4) / calories
  end

  def amount_label
    "#{grams.to_f.round} g"
  end
end
