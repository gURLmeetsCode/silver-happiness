# frozen_string_literal: true

require "rails_helper"

RSpec.describe MealEntry do
  it "requires a name" do
    entry = build(:meal_entry, name: nil)

    expect(entry).not_to be_valid
    expect(entry.errors[:name]).to be_present
  end

  it "exposes beverage as a meal type" do
    expect(described_class.meal_types.keys).to include("beverage")
  end

  describe "beverages" do
    it "records water logged alongside the entry" do
      log = create(:daily_log)
      product = create(:beverage_product, name: "Volvic 500 ml", water_volume_ml: 500, default_serving_g: 500)

      entry = log.meal_entries.create!(
        name: product.log_name,
        meal_type: :beverage,
        calories: 0,
        protein_g: 0
      )
      entry.update!(water_logged_ml: 500)
      log.add_water!(500)

      expect(entry).to be_meal_type_beverage
      expect(log.reload.water_ml).to eq(500)
      expect(entry.water_logged_ml).to eq(500)
    end

    it "refunds logged water when the entry is destroyed" do
      log = create(:daily_log, water_ml: 500)
      entry = create(:meal_entry, :beverage, daily_log: log, water_logged_ml: 500)

      entry.destroy!

      expect(log.reload.water_ml).to eq(0)
    end
  end
end
