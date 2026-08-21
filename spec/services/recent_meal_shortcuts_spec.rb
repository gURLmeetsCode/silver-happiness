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

  it "at lunchtime only offers recent lunches" do
    log_meal(date: today - 1.day, name: "Power salad", meal_type: :lunch)
    log_meal(date: today - 1.day, name: "Oats", meal_type: :breakfast)
    log_meal(date: today - 1.day, name: "Pasta dinner", meal_type: :dinner)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 12:30"))

    expect(result.slot_label).to eq("Lunch")
    expect(result.shortcuts.map(&:name)).to eq([ "Power salad" ])
  end

  it "at dinner time offers dinners and snacks, not breakfast" do
    log_meal(date: today - 1.day, name: "Oats", meal_type: :breakfast)
    log_meal(date: today - 1.day, name: "Brownies", meal_type: :snack, calories: 700)
    log_meal(date: today - 2.days, name: "Tofu dinner", meal_type: :dinner)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 18:30"))

    expect(result.slot_label).to eq("Dinner")
    expect(result.shortcuts.map(&:name)).to eq([ "Brownies", "Tofu dinner" ])
    expect(result.shortcuts.map(&:name)).not_to include("Oats")
  end

  it "prefers recipe-backed meals over plain copies" do
    template = create(:meal_template, :with_items)
    create(:recipe, meal_template: template, name: "Chipotle wrap")
    log_meal(date: today - 1.day, name: "Random lunch", meal_type: :lunch, calories: 500)
    log_meal(date: today - 2.days, name: "Chipotle wrap", meal_type: :lunch, template: template, calories: 440)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 12:00"))

    expect(result.shortcuts.first.name).to eq("Chipotle wrap")
    expect(result.shortcuts.first).to be_recipe
  end

  it "does not expose an archived recipe on the shortcut" do
    template = create(:meal_template, :with_items)
    create(:recipe, :archived, meal_template: template, name: "Old wrap")
    log_meal(date: today - 1.day, name: "Old wrap", meal_type: :lunch, template: template)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 12:00"))

    expect(result.shortcuts.first.recipe).to be_nil
    expect(result.shortcuts.first).not_to be_recipe
  end

  it "does not time-filter when viewing another day’s log" do
    log_meal(date: today - 1.day, name: "Oats", meal_type: :breakfast)
    log_meal(date: today - 1.day, name: "Dinner", meal_type: :dinner)

    result = described_class.call(
      as_of: today - 1.day,
      at: Time.zone.parse("#{today} 12:00")
    )

    expect(result.slot_label).to eq("Usual meals")
    expect(result.shortcuts.map(&:name)).to include("Oats", "Dinner")
  end

  it "skips beverages" do
    log_meal(date: today - 1.day, name: "Americano", meal_type: :beverage, calories: 5)
    log_meal(date: today - 1.day, name: "Lunch bowl", meal_type: :lunch)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 12:00"))
    expect(result.shortcuts.map(&:name)).to eq([ "Lunch bowl" ])
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

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 08:00"))
    expect(result.shortcuts.map(&:name)).to eq([ "Fiber greens" ])
  end

  it "dedupes by meal template and keeps the latest" do
    template = create(:meal_template, :with_items, name: "Power salad")
    log_meal(date: today - 3.days, name: "Power salad", meal_type: :lunch, template: template, calories: 350)
    latest = log_meal(date: today - 1.day, name: "Power salad (tweaked)", meal_type: :lunch, template: template, calories: 420)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 12:00"))

    expect(result.shortcuts.size).to eq(1)
    expect(result.shortcuts.first.source_entry).to eq(latest)
    expect(result.shortcuts.first.times_eaten).to eq(2)
  end

  it "ranks meals you eat often above a one-off" do
    3.times do |n|
      log_meal(date: today - (n + 2).days, name: "Oats", meal_type: :breakfast)
    end
    log_meal(date: today - 1.day, name: "Hotel buffet", meal_type: :breakfast)

    result = described_class.call(as_of: today, at: Time.zone.parse("#{today} 08:00"))

    expect(result.shortcuts.map(&:name)).to eq([ "Oats", "Hotel buffet" ])
    expect(result.shortcuts.first.times_eaten).to eq(3)
  end
end
