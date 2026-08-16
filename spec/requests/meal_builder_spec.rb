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

  it "records what the meal was made of" do
    post daily_log_meal_entries_path(daily_log), params: {
      items: {
        "0" => { product_id: zucchini.id, quantity: "0.5", unit: "cup" },
        "1" => { product_id: tofu.id, quantity: "0.5", unit: "serving" }
      },
      meal_entry: { meal_type: "dinner" }
    }

    entry = daily_log.meal_entries.last
    expect(entry.items.map { |i| [ i.product.name, i.grams.to_f ] }).to contain_exactly(
      [ "Zucchini", 120.0 ],
      [ "Tofu", 62.5 ]
    )
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
    template = create(:meal_template, name: "Roasted potatoes (batch)")
    create(:meal_template_item, meal_template: template, product: zucchini, quantity_g: 400)

    get daily_log_path(daily_log)

    expect(response.body).to include("Build a meal")
    expect(response.body).to include("items[0][picker]")
    expect(response.body).to include("items[0][unit]")
    expect(response.body).to include("Batch trays")
    expect(response.body).to include("Products")
    expect(response.body).to include("Roasted potatoes (batch)")
  end

  it "saves a meal built from scaled batches" do
    template = create(:meal_template, name: "Zucchini + tofu (batch)")
    create(:meal_template_item, meal_template: template, product: zucchini, quantity_g: 400)
    create(:meal_template_item, meal_template: template, product: tofu, quantity_g: 300)

    expect {
      post daily_log_meal_entries_path(daily_log), params: {
        items: {
          "0" => { picker: "template_#{template.id}", quantity: "0.5", unit: "serving" }
        },
        meal_entry: { meal_type: "dinner" }
      }
    }.to change(daily_log.meal_entries, :count).by(1)

    entry = daily_log.meal_entries.last
    expect(entry.name).to eq("Zucchini + tofu (batch)")
    expect(entry.items.map { |i| [ i.product.name, i.grams.to_f ] }).to contain_exactly(
      [ "Zucchini", 200.0 ],
      [ "Tofu", 150.0 ]
    )
  end
end
