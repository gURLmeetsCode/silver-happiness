# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpenFoodFacts do
  it "prefers the French product name and per-100g nutrition" do
    payload = {
      "code" => "3259011034000",
      "product_name_fr" => "Tofu nature à cuisiner",
      "brands" => "Céréal Bio",
      "nutriments" => {
        "energy-kcal_100g" => 145,
        "proteins_100g" => 14,
        "carbohydrates_100g" => 0.8,
        "fat_100g" => 9
      }
    }

    result = described_class.new("3259011034000").send(:parse, payload)

    expect(result[:name]).to eq("Tofu nature à cuisiner")
    expect(result[:brand]).to eq("Céréal Bio")
    expect(result[:calories_per_100g]).to eq(145)
    expect(result[:protein_per_100g]).to eq(14)
  end
end
