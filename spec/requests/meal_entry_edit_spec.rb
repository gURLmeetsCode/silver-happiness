# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editing built meal ingredients", type: :request do
  before { Goal.current }

  let(:daily_log) { DailyLog.today }
  let(:chickpeas) do
    create(:product, name: "Chickpeas", default_serving_g: 100,
      calories_per_100g: 164, protein_per_100g: 9, carbs_per_100g: 27, fat_per_100g: 2.6)
  end
  let(:tahini) do
    create(:product, name: "Tahini", default_serving_g: 15,
      calories_per_100g: 595, protein_per_100g: 17, carbs_per_100g: 21, fat_per_100g: 54)
  end

  it "lets you change the parts of a built meal" do
    entry = create(:meal_entry, daily_log: daily_log, name: "Hummus plate", meal_type: :lunch)
    create(:meal_entry_item, meal_entry: entry, product: chickpeas, grams: 100)

    patch daily_log_meal_entry_path(daily_log, entry), params: {
      items: {
        "0" => { picker: "product_#{chickpeas.id}", quantity: "80", unit: "g" },
        "1" => { picker: "product_#{tahini.id}", quantity: "1", unit: "serving" }
      },
      meal_entry: { name: "Oil-free hummus", meal_type: "snack" }
    }

    entry.reload
    expect(entry.name).to eq("Oil-free hummus")
    expect(entry.meal_type).to eq("snack")
    expect(entry.items.map { |i| [ i.product.name, i.grams.to_f ] }).to contain_exactly(
      [ "Chickpeas", 80.0 ],
      [ "Tahini", 15.0 ]
    )
    expect(entry.calories).to be > 0
  end

  it "shows the ingredient editor for built meals" do
    entry = create(:meal_entry, daily_log: daily_log, name: "Hummus plate")
    create(:meal_entry_item, meal_entry: entry, product: chickpeas, grams: 100)

    get edit_daily_log_meal_entry_path(daily_log, entry)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Edit ingredients")
    expect(response.body).to include("product_#{chickpeas.id}")
  end
end
