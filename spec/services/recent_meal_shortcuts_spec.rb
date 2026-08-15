# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecentMealShortcuts do
  let(:today) { Date.current }
  let(:tofu) { create(:product, name: "Tofu", calories_per_100g: 145, protein_per_100g: 16) }

  def log_meal(date:, name:, meal_type: :dinner, template: nil, calories: 400, protein: 20)
    log = DailyLog.find_or_create_by!(logged_on: date)
    entry = log.meal_entries.create!(
      name: name,
      meal_type: meal_type,
      calories: calories,
      protein_g: protein,
      carbs_g: 30,
      fat_g: 10,
      meal_template: template
    )
    entry.record_items!([ { product_id: tofu.id, grams: 125 } ])
    entry.save!
    entry
  end

  it "returns unique meals from the last week, newest first" do
    older = log_meal(date: today - 2.days, name: "Power salad", calories: 380)
    newer = log_meal(date: today - 1.day, name: "Cinema snack", calories: 686)
    log_meal(date: today - 10.days, name: "Too old")

    shortcuts = described_class.call(as_of: today)

    expect(shortcuts.map(&:name)).to eq([ "Cinema snack", "Power salad" ])
    expect(shortcuts.first.source_entry).to eq(newer)
    expect(shortcuts.second.source_entry).to eq(older)
  end

  it "dedupes by meal template and keeps the latest" do
    template = create(:meal_template, :with_items, name: "Power salad")
    log_meal(date: today - 3.days, name: "Power salad", template: template, calories: 350)
    latest = log_meal(date: today - 1.day, name: "Power salad (tweaked)", template: template, calories: 420)

    shortcuts = described_class.call(as_of: today)

    expect(shortcuts.size).to eq(1)
    expect(shortcuts.first.source_entry).to eq(latest)
    expect(shortcuts.first.calories).to eq(420)
  end

  it "skips beverages" do
    log_meal(date: today - 1.day, name: "Americano", meal_type: :beverage, calories: 5)
    log_meal(date: today - 1.day, name: "Lunch bowl", meal_type: :lunch)

    expect(described_class.call(as_of: today).map(&:name)).to eq([ "Lunch bowl" ])
  end

  it "attaches the recipe when the template has one" do
    template = create(:meal_template, :with_items)
    recipe = create(:recipe, meal_template: template, name: "Chipotle wrap")
    log_meal(date: today - 1.day, name: "Chipotle wrap", template: template)

    shortcut = described_class.call(as_of: today).first
    expect(shortcut.recipe).to eq(recipe)
    expect(shortcut).to be_recipe
  end

  it "hides a single-ingredient meal when a built meal already includes that product" do
    greens = create(:product, name: "Strong greens")
    psyllium = create(:product, name: "Psyllium husk")

    log = DailyLog.find_or_create_by!(logged_on: today - 1.day)
    fiber = log.meal_entries.create!(
      name: "Fiber greens", meal_type: :breakfast,
      calories: 50, protein_g: 2, carbs_g: 10, fat_g: 0
    )
    fiber.record_items!([ { product_id: greens.id, grams: 80 }, { product_id: psyllium.id, grams: 10 } ])
    fiber.save!

    alone = log.meal_entries.create!(
      name: "Psyllium husk (morning)", meal_type: :breakfast,
      calories: 35, protein_g: 0, carbs_g: 8, fat_g: 0
    )
    alone.record_items!([ { product_id: psyllium.id, grams: 10 } ])
    alone.save!

    expect(described_class.call(as_of: today).map(&:name)).to eq([ "Fiber greens" ])
  end
end
