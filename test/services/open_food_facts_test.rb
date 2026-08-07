# frozen_string_literal: true

require "test_helper"

class OpenFoodFactsTest < ActiveSupport::TestCase
  test "parse uses French product name and per 100g nutrition" do
    payload = {
      "status" => 1,
      "product" => {
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
    }

    result = OpenFoodFacts.new("3259011034000").send(:parse, payload["product"])

    assert_equal "Tofu nature à cuisiner", result[:name]
    assert_equal "Céréal Bio", result[:brand]
    assert_equal 145, result[:calories_per_100g]
    assert_equal 14, result[:protein_per_100g]
  end
end
