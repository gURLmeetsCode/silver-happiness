# frozen_string_literal: true

require "test_helper"

class GroceryChecksControllerTest < ActionDispatch::IntegrationTest
  test "toggle checks an item" do
    post toggle_grocery_checks_path, params: { item_key: "batch:veg" }, as: :json
    assert_response :success
    assert JSON.parse(response.body)["checked"]
  end

  test "reset clears checks for current period" do
    period = ShoppingPeriod.current
    GroceryCheck.create!(shopping_period: period, item_key: "batch:veg", checked: true)

    delete reset_grocery_checks_path
    assert_redirected_to grocery_recipes_path
    assert_empty GroceryCheck.for_period(period)
  end
end
