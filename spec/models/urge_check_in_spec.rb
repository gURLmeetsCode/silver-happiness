# frozen_string_literal: true

require "rails_helper"

RSpec.describe UrgeCheckIn, type: :model do
  it "requires a known feeling, protein status, delay, and outcome" do
    urge = build_urge(feeling: "angry")
    expect(urge).not_to be_valid

    urge = build_urge
    expect(urge).to be_valid
  end

  it "knows when the urge was paused" do
    expect(build_urge(outcome: "paused")).to be_paused
    expect(build_urge(outcome: "ate_anyway")).not_to be_paused
  end

  def build_urge(**attrs)
    described_class.new({
      daily_log: DailyLog.today,
      feeling: "bored",
      protein_status: "unsure",
      delay_action: "walk",
      outcome: "paused"
    }.merge(attrs))
  end
end

RSpec.describe DailyLog, type: :model do
  describe "#protein_status_suggestion" do
    it "returns unsure with no meals" do
      expect(DailyLog.today.protein_status_suggestion).to eq("unsure")
    end

    it "returns yes when protein meets the minimum" do
      log = DailyLog.today
      create(:meal_entry, daily_log: log, protein_g: Goal.current.protein_min_g, calories: 500)

      expect(log.protein_status_suggestion).to eq("yes")
    end

    it "returns no when protein is well under the minimum" do
      log = DailyLog.today
      create(:meal_entry, daily_log: log, protein_g: 10, calories: 200)

      expect(log.protein_status_suggestion).to eq("no")
    end
  end
end
