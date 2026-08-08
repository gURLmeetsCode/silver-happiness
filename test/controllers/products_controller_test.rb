# frozen_string_literal: true

require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "lookup_barcode returns product nutrition as json" do
    payload = {
      "code" => "3259011034000",
      "product_name_fr" => "Test Product",
      "brands" => "Test Brand",
      "nutriments" => {
        "energy-kcal_100g" => 42,
        "proteins_100g" => 3.5,
        "carbohydrates_100g" => 5.1,
        "fat_100g" => 1.2
      }
    }

    OpenFoodFacts.stub(:lookup, {
      barcode: "3259011034000",
      name: "Test Product",
      brand: "Test Brand",
      calories_per_100g: 42,
      protein_per_100g: 3.5,
      carbs_per_100g: 5.1,
      fat_per_100g: 1.2
    }) do
      post lookup_barcode_products_path, params: { barcode: "3259011034000" }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Test Product", json["name"]
    assert_equal 42, json["calories_per_100g"]
  end

  test "new product page wires barcode scanner to form fields" do
    get new_product_path
    assert_response :success
    assert_select "[data-controller='barcode-scanner'] [data-barcode-scanner-target='name']"
    assert_select "[data-controller='barcode-scanner'] [data-barcode-scanner-target='calories']"
  end
end
