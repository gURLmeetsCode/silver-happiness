# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyTargetSuggestions do
  let!(:goal) { Goal.current }
  let(:log) { create(:daily_log, :with_run) }

  it "shows calorie tips when over the training-day target" do
    log.meal_entries.create!(meal_type: :breakfast, name: "Oats", calories: 900, protein_g: 36)
    log.meal_entries.create!(meal_type: :lunch, name: "Power salad lunch", calories: 485, protein_g: 23, notes: "2 tbsp dressing")
    log.meal_entries.create!(meal_type: :dinner, name: "Pasta salad + tofu", calories: 892, protein_g: 39, notes: "2 tbsp Puget oil")

    suggestions = described_class.new(log)

    expect(suggestions).to be_relevant
    expect(suggestions.headline).to match(/over today's/)
    expect(suggestions.suggestions).to be_any { |tip| tip.message.match?(/dressing|oil|Puget/i) }
  end

  it "shows protein tips when under the minimum" do
    log.meal_entries.create!(meal_type: :breakfast, name: "Light breakfast", calories: 200, protein_g: 10)

    suggestions = described_class.new(log)

    expect(suggestions).to be_relevant
    expect(suggestions.headline).to match(/below your 90 g protein/)
    expect(suggestions.suggestions).to be_any { |tip| tip.adds_protein_g.positive? }
  end

  it "stays hidden when on target" do
    log.meal_entries.create!(meal_type: :breakfast, name: "Oats", calories: 348, protein_g: 95)

    expect(described_class.new(log)).not_to be_relevant
  end
end
