# frozen_string_literal: true

require "test_helper"

class DailyTargetSuggestionsTest < ActiveSupport::TestCase
  setup do
    @goal = Goal.current
    @log = DailyLog.create!(logged_on: Date.new(2026, 8, 7), run_km: 8, run_calories: 448)
  end

  test "shows calorie tips when over training day target" do
    @log.meal_entries.create!(meal_type: :breakfast, name: "Oats", calories: 900, protein_g: 36)
    @log.meal_entries.create!(meal_type: :lunch, name: "Power salad lunch", calories: 485, protein_g: 23, notes: "2 tbsp dressing")
    @log.meal_entries.create!(meal_type: :dinner, name: "Pasta salad + tofu", calories: 892, protein_g: 39, notes: "2 tbsp Puget oil")

    suggestions = DailyTargetSuggestions.new(@log)

    assert suggestions.relevant?
    assert_match(/over today's/, suggestions.headline)
    assert suggestions.suggestions.any? { |tip| tip.message.match?(/dressing|oil|Puget/i) }
  end

  test "shows protein tips when under minimum" do
    @log.meal_entries.create!(meal_type: :breakfast, name: "Light breakfast", calories: 200, protein_g: 10)

    suggestions = DailyTargetSuggestions.new(@log)

    assert suggestions.relevant?
    assert_match(/below your 90 g protein/, suggestions.headline)
    assert suggestions.suggestions.any? { |tip| tip.adds_protein_g.positive? }
  end

  test "hidden when on target" do
    @log.meal_entries.create!(meal_type: :breakfast, name: "Oats", calories: 348, protein_g: 95)

    suggestions = DailyTargetSuggestions.new(@log)

    assert_not suggestions.relevant?
  end
end
