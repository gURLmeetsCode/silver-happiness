# frozen_string_literal: true

class AddSweetAndYellowPotatoProducts < ActiveRecord::Migration[8.0]
  PRODUCTS = [
    {
      name: "Sweet potato",
      brand: nil,
      calories_per_100g: 86, protein_per_100g: 1.5, carbs_per_100g: 18.3, fat_per_100g: 0.2,
      default_serving_g: 200, serving_label: "1 whole medium (~200 g)",
      notes: "CIQUAL patate douce, raw flesh. Log raw weight before roasting — " \
             "1 whole medium sweet potato ≈ 200 g."
    },
    {
      name: "Yellow potato",
      brand: nil,
      calories_per_100g: 81, protein_per_100g: 1.9, carbs_per_100g: 16.7, fat_per_100g: 0.2,
      default_serving_g: 150, serving_label: "1 medium/small (~150 g)",
      notes: "CIQUAL pomme de terre (peeled, raw). Yellow/plain table potato. " \
             "Log raw weight before roasting — medium/small ≈ 150 g each."
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
