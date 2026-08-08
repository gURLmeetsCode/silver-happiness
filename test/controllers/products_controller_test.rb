# frozen_string_literal: true

require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "lookup_barcode returns product nutrition as json" do
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

  test "new product page uses manual barcode lookup without camera" do
    get new_product_path
    assert_response :success
    assert_select "[data-controller='barcode-lookup'] [data-barcode-lookup-target='name']"
    assert_select "[data-action='barcode-lookup#lookupManual']"
    assert_no_match(/startScan|Open scanner|barcode-scanner/, response.body)
  end
end
