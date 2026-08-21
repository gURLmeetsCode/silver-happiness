# frozen_string_literal: true

require "rails_helper"

RSpec.describe Goal, type: :model do
  describe "#suggested_protein_range" do
    it "scales ~1.6–1.8 g per kg of target weight" do
      goal = build(:goal, target_weight_kg: 56)

      expect(goal.suggested_protein_range).to eq(min_g: 90, max_g: 101)
    end
  end

  describe "#suggested_calorie_targets" do
    it "uses recommended intake for rest and +100 for training" do
      goal = build(:goal)
      energy = goal.energy_estimate
      targets = goal.suggested_calorie_targets

      expect(targets[:rest_day]).to eq(energy.recommended_intake)
      expect(targets[:training_day]).to eq(energy.recommended_intake + 100)
    end
  end

  describe "#apply_suggested_targets!" do
    it "writes protein and calorie fields" do
      goal = build(:goal, target_weight_kg: 54, protein_min_g: 50, protein_max_g: 60,
                   calories_rest_day: 1000, calories_training_day: 1100)

      goal.apply_suggested_targets!

      expect(goal.protein_min_g).to eq(86)
      expect(goal.protein_max_g).to eq(97)
      expect(goal.calories_rest_day).to eq(goal.energy_estimate.recommended_intake)
      expect(goal.calories_training_day).to eq(goal.calories_rest_day + 100)
    end
  end
end
