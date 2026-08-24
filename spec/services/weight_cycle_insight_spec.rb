# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeightCycleInsight do
  let!(:goal) { Goal.current }

  it "builds weight and period marker series" do
    create(:daily_log, logged_on: Date.current - 2, weight_kg: 57.0, on_period: false)
    create(:daily_log, logged_on: Date.current - 1, weight_kg: 57.8, on_period: true)
    create(:daily_log, logged_on: Date.current, weight_kg: 58.0, on_period: true)

    result = described_class.call(goal: goal)

    expect(result.weight_series.map(&:last)).to eq([ 57.0, 57.8, 58.0 ])
    expect(result.period_weight_series.map(&:last)).to eq([ nil, 57.8, 58.0 ])
    expect(result.period_days_with_weight).to eq(2)
    expect(result.off_days_with_weight).to eq(1)
  end

  it "compares on-period vs off-period averages when there is enough data" do
    2.times do |n|
      create(:daily_log, logged_on: Date.current - (10 + n), weight_kg: 56.0, on_period: false)
    end
    2.times do |n|
      create(:daily_log, logged_on: Date.current - n, weight_kg: 57.0, on_period: true)
    end

    result = described_class.call(goal: goal)

    expect(result).to be_enough_to_compare
    expect(result.on_period_avg).to eq(57.0)
    expect(result.off_period_avg).to eq(56.0)
    expect(result.cycle_delta).to eq(1.0)
    expect(result.summary).to include("1.0 kg higher")
  end

  it "explains what to do when period days are scarce" do
    create(:daily_log, logged_on: Date.current, weight_kg: 57.0, on_period: false)

    result = described_class.call(goal: goal)

    expect(result).not_to be_enough_to_compare
    expect(result.summary).to include("On my period today")
  end
end
