# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpenFoodFacts do
  describe "#parse" do
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

      result = described_class.new(barcode: "3259011034000").send(:parse, payload)

      expect(result[:name]).to eq("Tofu nature à cuisiner")
      expect(result[:brand]).to eq("Céréal Bio")
      expect(result[:calories_per_100g]).to eq(145)
      expect(result[:protein_per_100g]).to eq(14)
    end
  end

  describe ".search" do
    it "returns parsed matches from Open Food Facts" do
      allow_any_instance_of(described_class).to receive(:fetch_search).and_return([
        {
          "code" => "3273220181003",
          "product_name_fr" => "Yaourt nature",
          "brands" => "Sojasun",
          "nutriments" => {
            "energy-kcal_100g" => 43,
            "proteins_100g" => 4.0,
            "carbohydrates_100g" => 2.5,
            "fat_100g" => 2.0
          }
        }
      ])

      results = described_class.search("sojasun yaourt")

      expect(results.length).to eq(1)
      expect(results.first[:name]).to eq("Yaourt nature")
      expect(results.first[:brand]).to eq("Sojasun")
      expect(results.first[:calories_per_100g]).to eq(43)
    end

    it "raises when the query is too short" do
      expect { described_class.search("a") }.to raise_error(OpenFoodFacts::NotFound, /2 characters/)
    end
  end
end
