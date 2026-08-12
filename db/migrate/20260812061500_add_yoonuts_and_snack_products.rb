# frozen_string_literal: true

class AddYoonutsAndSnackProducts < ActiveRecord::Migration[8.0]
  PRODUCTS = [
    {
      name: "Yoonuts Muesli croustillant 4 fruits rouges",
      brand: "Yoonuts",
      calories_per_100g: 437, protein_per_100g: 10, carbs_per_100g: 59, fat_per_100g: 16,
      default_serving_g: 100, serving_label: "1 cup (~100 g)",
      notes: "Label (Yoonuts pro): 437 kcal · 16 g fat · 59 g carbs · 10 g protein / 100 g. " \
             "Cup weight for croustillant muesli ≈ 100 g."
    },
    {
      name: "Yoonuts Muesli croustillant 4 noix",
      brand: "Yoonuts",
      calories_per_100g: 469, protein_per_100g: 11, carbs_per_100g: 55, fat_per_100g: 21,
      default_serving_g: 100, serving_label: "1 cup (~100 g)",
      notes: "Label (Yoonuts pro): 469 kcal · 21 g fat · 55 g carbs · 11 g protein / 100 g."
    },
    {
      name: "Brazil nuts",
      brand: nil,
      calories_per_100g: 659, protein_per_100g: 14.3, carbs_per_100g: 12.3, fat_per_100g: 67.1,
      default_serving_g: 133, serving_label: "1 cup whole (~133 g)",
      notes: "USDA dried unblanched. 1 cup is a very large selenium dose — usual portion is a few nuts."
    },
    {
      name: "Almonds",
      brand: nil,
      calories_per_100g: 579, protein_per_100g: 21.2, carbs_per_100g: 21.6, fat_per_100g: 49.9,
      default_serving_g: 72, serving_label: "0.5 cup whole (~72 g)",
      notes: "CIQUAL / common whole-almond figures. 0.5 cup ≈ 72 g."
    },
    {
      name: "Nectarine",
      brand: nil,
      calories_per_100g: 44, protein_per_100g: 1.2, carbs_per_100g: 8.9, fat_per_100g: 0.3,
      default_serving_g: 140, serving_label: "1 medium (~140 g)",
      notes: "CIQUAL nectarine/brugnon, flesh and skin, raw."
    },
    {
      name: "Tortilla chips",
      brand: nil,
      calories_per_100g: 488, protein_per_100g: 7.0, carbs_per_100g: 63.0, fat_per_100g: 23.0,
      default_serving_g: 50, serving_label: "1 handful (~50 g)",
      notes: "Typical corn tortilla chips average. Adjust grams if you know the bag weight."
    },
    {
      name: "Psyllium husk",
      brand: nil,
      calories_per_100g: 350, protein_per_100g: 0, carbs_per_100g: 80, fat_per_100g: 0,
      default_serving_g: 10, serving_label: "1 tbsp (~10 g)",
      notes: "Mostly fibre. ~35 kcal per tablespoon; take with plenty of water."
    },
    {
      name: "Vegan cake-sale muffin with vegan feta",
      brand: nil,
      calories_per_100g: 280, protein_per_100g: 6, carbs_per_100g: 32, fat_per_100g: 14,
      default_serving_g: 125, serving_label: "1 muffin + feta (~125 g)",
      notes: "Estimate for a cake-sale vegan muffin topped with vegan feta (~350 kcal). " \
             "No label — rough only."
    }
  ].freeze

  def up
    PRODUCTS.each do |attrs|
      product = Product.find_or_initialize_by(name: attrs[:name])
      product.assign_attributes(attrs)
      product.save!
    end
  end

  def down
    PRODUCTS.each { |attrs| Product.find_by(name: attrs[:name])&.destroy }
  end
end
