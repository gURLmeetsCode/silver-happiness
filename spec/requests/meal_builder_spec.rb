# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Building a meal from several items", type: :request do
  before { Goal.current }

  let(:daily_log) { DailyLog.today }

  let(:zucchini) do
    create(:product, name: "Zucchini", default_serving_g: 100, serving_label: "½ zucchini (~100 g)",
      calories_per_100g: 17, protein_per_100g: 1.2, carbs_per_100g: 3.1, fat_per_100g: 0.3)
  end

  let(:tofu) do
    create(:product, name: "Tofu", default_serving_g: 125, serving_label: "1 pavé (125 g)",
      calories_per_100g: 145, protein_per_100g: 16, carbs_per_100g: 2, fat_per_100g: 8)
  end

  it "saves one meal made of several items" do
    expect {
      post daily_log_meal_entries_path(daily_log), params: {
        items: {
          "0" => { product_id: zucchini.id, quantity: "0.5", unit: "cup" },
          "1" => { product_id: tofu.id, quantity: "0.5", unit: "serving" }
        },
        meal_entry: { meal_type: "dinner" }
      }
    }.to change(daily_log.meal_entries, :count).by(1)

    entry = daily_log.meal_entries.last
    expect(entry.calories).to eq(111)
    expect(entry.meal_type).to eq("dinner")
  end

  it "names the meal from its items when no name is given" do
    post daily_log_meal_entries_path(daily_log), params: {
      items: { "0" => { product_id: tofu.id, quantity: "1", unit: "serving" } },
      meal_entry: { meal_type: "dinner" }
    }

    expect(daily_log.meal_entries.last.name).to eq("Tofu")
  end

  it "keeps a name you chose yourself" do
    post daily_log_meal_entries_path(daily_log), params: {
      items: { "0" => { product_id: tofu.id, quantity: "1", unit: "serving" } },
      meal_entry: { meal_type: "dinner", name: "Tofu bowl" }
    }

    expect(daily_log.meal_entries.last.name).to eq("Tofu bowl")
  end

  it "records the amounts in the notes" do
    post daily_log_meal_entries_path(daily_log), params: {
      items: { "0" => { product_id: zucchini.id, quantity: "0.5", unit: "cup" } },
      meal_entry: { meal_type: "dinner" }
    }

    expect(daily_log.meal_entries.last.notes).to include("Zucchini")
    expect(daily_log.meal_entries.last.notes).to include("120 g")
  end

  it "explains itself when nothing was filled in" do
    expect {
      post daily_log_meal_entries_path(daily_log), params: {
        items: { "0" => { product_id: "", quantity: "", unit: "g" } },
        meal_entry: { meal_type: "dinner" }
      }
    }.not_to change(MealEntry, :count)

    expect(response).to redirect_to(daily_log_path(daily_log, anchor: "meals"))
    expect(flash[:alert]).to include("at least one item")
  end

  it "offers the builder on the day page" do
    zucchini

    get daily_log_path(daily_log)

    expect(response.body).to include("Build a meal")
    expect(response.body).to include("items[0][product_id]")
    expect(response.body).to include("items[0][unit]")
  end
end
