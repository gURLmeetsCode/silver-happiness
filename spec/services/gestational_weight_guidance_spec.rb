# frozen_string_literal: true

require "rails_helper"

RSpec.describe GestationalWeightGuidance do
  describe ".bmi" do
    it "computes BMI from kg and cm" do
      # 58.6 kg at 163 cm ≈ 22.1
      expect(described_class.bmi(58.6, 163)).to eq(22.1)
    end
  end

  describe "IOM bands" do
    it "maps normal BMI to 11.3–15.9 kg total gain" do
      band = described_class.band_for_bmi(22.1)

      expect(band[:key]).to eq(:normal)
      expect(band[:total_min_kg]).to eq(11.3)
      expect(band[:total_max_kg]).to eq(15.9)
    end
  end

  describe "instance guidance" do
    let(:goal) do
      build(:goal,
            life_stage: "pregnancy",
            height_cm: 163,
            pre_pregnancy_weight_kg: 58.6,
            pregnancy_lmp_on: Date.current - 20.weeks)
    end

    it "is ready with LMP, height, and pre-pregnancy weight" do
      guide = described_class.new(goal)

      expect(guide).to be_ready
      expect(guide.gestational_week).to eq(21)
      expect(guide.trimester).to eq(2)
      expect(guide.expected_lower_gain_kg).to be_positive
      expect(guide.term_lower_weight_kg).to eq((58.6 + 11.3).round(1))
    end

    it "flags being on the lower path when gain matches expected" do
      guide = described_class.new(goal)
      weight = guide.expected_lower_weight_kg

      expect(guide.gain_status(weight)).to eq(:on_lower_path)
    end
  end
end
