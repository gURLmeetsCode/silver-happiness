# frozen_string_literal: true

class AddBrangeonCroissantProduct < ActiveRecord::Migration[8.0]
  def up
    product = Product.find_or_initialize_by(name: "Croissant au beurre")
    product.assign_attributes(
      brand: "Boulangerie Frédéric Brangeon",
      calories_per_100g: 424,
      protein_per_100g: 7.1,
      carbs_per_100g: 43.2,
      fat_per_100g: 23.3,
      default_serving_g: 55,
      serving_label: "1 croissant (~55 g)",
      notes: "CIQUAL artisanal butter croissant (Anses). Brangeon does not list macros — " \
             "~233 kcal for a 55 g croissant."
    )
    product.save!
  end

  def down
    Product.find_by(name: "Croissant au beurre", brand: "Boulangerie Frédéric Brangeon")&.destroy
  end
end
