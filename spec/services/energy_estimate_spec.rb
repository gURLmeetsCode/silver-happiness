# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnergyEstimate do
  # Profile matching the real goals: 37, 163 cm, female, moderate activity.
  let(:goal) do
    build(:goal,
      height_cm: 163, age_years: 37, sex: "female",
      activity_level: "moderate", starting_weight_kg: 59.5,
      target_deficit_kcal: 400)
  end

  subject(:estimate) { described_class.new(goal) }

  it "computes Mifflin–St Jeor BMR for a woman" do
    # 10×59.5 + 6.25×163 − 5×37 − 161 = 1,268
    expect(estimate.bmr).to eq(1268)
  end

  it "scales BMR by the activity multiplier for TDEE" do
    # 1,268 × 1.55 ≈ 1,965
    expect(estimate.tdee).to eq(1965)
  end

  it "recommends a 400 kcal deficit and ~0.36 kg/week" do
    expect(estimate.recommended_deficit).to eq(400)
    expect(estimate.recommended_intake).to eq(1565)
    expect(estimate.expected_weekly_loss_kg).to eq(0.36)
  end

  it "turns eaten calories into a day's deficit against maintenance" do
    expect(estimate.deficit_for(1565)).to eq(400)
    expect(estimate.deficit_for(2165)).to eq(-200)
  end

  it "keeps recommended intake at or above 1,200 even with a large deficit" do
    goal.target_deficit_kcal = 900

    expect(estimate.recommended_intake).to eq(1200)
  end

  it "is not ready without height and age" do
    goal.height_cm = nil
    goal.age_years = nil

    expect(estimate).not_to be_ready
    expect(estimate.summary_line).to match(/Add height/)
  end
end
