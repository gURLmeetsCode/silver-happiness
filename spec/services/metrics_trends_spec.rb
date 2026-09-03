# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetricsTrends do
  let(:goal) { Goal.current }

  def log_day(date, calories:, weight: nil, meal_name: "Meals")
    log = DailyLog.find_or_create_by!(logged_on: date)
    log.update!(weight_kg: weight) if weight
    create(:meal_entry, daily_log: log, name: meal_name, calories: calories, meal_type: :lunch)
    log
  end

  it "returns not ready with sparse data" do
    result = described_class.call(goal: goal, as_of: Date.new(2026, 9, 5))

    expect(result).not_to be_ready
    expect(result.insights).to be_empty
  end

  it "surfaces weekend leak, maintenance gap, and rolling weight" do
    travel_to Time.zone.local(2026, 9, 5, 12, 0, 0) do
      (Date.new(2026, 8, 24)..Date.new(2026, 8, 28)).each_with_index do |date, i|
        log_day(date, calories: 1700, weight: 58.0 - (i * 0.05))
      end
      log_day(Date.new(2026, 8, 29), calories: 2500, weight: 58.2, meal_name: "Nora Cooks brownies")
      log_day(Date.new(2026, 8, 30), calories: 2400, weight: 58.4)
      (Date.new(2026, 8, 31)..Date.new(2026, 9, 4)).each_with_index do |date, i|
        log_day(date, calories: 1700, weight: 57.8 - (i * 0.05))
      end
      # Extra brownie day over 2100 for spikes
      log = DailyLog.find_by!(logged_on: Date.new(2026, 8, 29))
      create(:meal_entry, daily_log: log, name: "Nora Cooks oil-free walnut brownies", calories: 800)

      result = described_class.call(goal: goal, as_of: Date.new(2026, 9, 5))

      expect(result).to be_ready
      expect(result.weekday_avg).to be < result.weekend_avg
      expect(result.rolling_weight_series).not_to be_empty
      expect(result.weekly_avg_eaten).not_to be_empty
      expect(result.insights.map(&:title).join).to match(/Weekend|maintenance|7-day|High days|goal/i)
      expect(result.spikes.first.calories).to be >= 2100
      expect(result.headline).to be_present
    end
  end
end
