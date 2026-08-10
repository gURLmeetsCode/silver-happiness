# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyTargetSuggestions do
  let!(:goal) { Goal.current }
  let(:log) { create(:daily_log, :with_run) }

  let!(:dressing) do
    create(:product, name: "Homemade salad dressing",
      calories_per_100g: 533, protein_per_100g: 0.5, carbs_per_100g: 5, fat_per_100g: 55,
      default_serving_g: 30, serving_label: "2 tbsp")
  end

  let!(:olive_oil) do
    create(:product, name: "Puget Huile d'olive",
      calories_per_100g: 900, protein_per_100g: 0, carbs_per_100g: 0, fat_per_100g: 100,
      default_serving_g: 10, serving_label: "1 tbsp (10 g)")
  end

  let!(:tofu) do
    create(:product, name: "Tofu",
      calories_per_100g: 145, protein_per_100g: 16, carbs_per_100g: 2, fat_per_100g: 8,
      default_serving_g: 125, serving_label: "1 pavé (125 g)", quick_log: true)
  end

  def add_meal(name:, calories:, protein:, items: [])
    entry = log.meal_entries.create!(meal_type: :dinner, name: name, calories: calories, protein_g: protein)
    items.each_with_index do |(product, grams), index|
      entry.items.create!(product: product, grams: grams, position: index)
    end
    entry
  end

  it "names a real item that was logged and the amount that would help" do
    add_meal(
      name: "Power salad", calories: 900, protein: 50,
      items: [ [ dressing, 30 ], [ tofu, 125 ] ]
    )
    # Push the day well over the 1700 training-day target.
    add_meal(name: "Pasta bowl", calories: 1100, protein: 50, items: [ [ olive_oil, 20 ] ])

    suggestions = described_class.new(log)

    expect(suggestions).to be_relevant
    expect(suggestions.headline).to match(/over today's/)

    messages = suggestions.suggestions.map(&:message)
    expect(messages).to include(a_string_matching(/Homemade salad dressing.*Power salad/))
    expect(messages).to include(a_string_matching(/Puget Huile d'olive.*Pasta bowl/))
    # Tofu is dense protein — leave it alone even though it has calories.
    expect(messages).not_to include(a_string_matching(/Tofu/))
  end

  it "does not invent tips about food that was never logged" do
    add_meal(name: "Oats", calories: 2200, protein: 95)

    suggestions = described_class.new(log)

    expect(suggestions).to be_relevant
    expect(suggestions.headline).to match(/over today's/)
    expect(suggestions.suggestions).to be_empty
  end

  it "computes the exact calorie saving from half the amount" do
    add_meal(name: "Salad", calories: 500, protein: 50, items: [ [ dressing, 30 ] ])
    add_meal(name: "Extra", calories: 1500, protein: 50)

    tip = described_class.new(log).suggestions.find { |t| t.message.include?("dressing") }

    # Half of 30 g at 533 kcal/100g is 80 kcal.
    expect(tip.savings_kcal).to eq(80)
    expect(tip.message).to include("15 g").and include("30 g")
  end

  it "shows protein tips drawn from real products when under the minimum" do
    add_meal(name: "Light breakfast", calories: 200, protein: 10)

    suggestions = described_class.new(log)

    expect(suggestions).to be_relevant
    expect(suggestions.headline).to match(/below your 90 g protein/)
    expect(suggestions.suggestions).to be_any { |tip| tip.message.include?("Tofu") && tip.adds_protein_g.positive? }
  end

  it "stays hidden when on target" do
    add_meal(name: "Oats", calories: 348, protein: 95)

    expect(described_class.new(log)).not_to be_relevant
  end
end
