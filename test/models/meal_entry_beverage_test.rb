# frozen_string_literal: true

require "test_helper"

class MealEntryBeverageTest < ActiveSupport::TestCase
  test "logging a beverage product with water volume adds to daily water total" do
    log = DailyLog.create!(logged_on: Date.new(2026, 8, 8))
    product = Product.create!(
      name: "Volvic 500 ml",
      calories_per_100g: 0,
      protein_per_100g: 0,
      quick_log: true,
      beverage: true,
      default_serving_g: 500,
      water_volume_ml: 500
    )

    entry = log.meal_entries.create!(
      name: product.log_name,
      meal_type: product.quick_log_meal_type,
      calories: 0,
      protein_g: 0
    )
    entry.update!(water_logged_ml: 500)
    log.add_water!(500)

    assert entry.meal_type_beverage?
    assert_equal 500, log.reload.water_ml
    assert_equal 500, entry.water_logged_ml
  end
end
