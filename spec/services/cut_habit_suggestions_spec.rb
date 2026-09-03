# frozen_string_literal: true

require "rails_helper"

RSpec.describe CutHabitSuggestions do
  let(:goal) { Goal.current }
  let(:saturday) { Date.new(2026, 9, 5) }

  def log_day(date, calories:, run_km: nil, water_ml: 0, meal_name: "Meals", extra: nil)
    log = DailyLog.find_or_create_by!(logged_on: date)
    log.update!(run_km: run_km, run_calories: run_km && 300, water_ml: water_ml)
    create(:meal_entry, daily_log: log, name: meal_name, calories: calories, meal_type: :lunch)
    extra&.call(log)
    log
  end

  it "returns nothing in pregnancy mode" do
    goal.update!(life_stage: "pregnancy", pregnancy_lmp_on: saturday - 80)

    result = described_class.call(goal: goal, today: DailyLog.for_date(saturday))

    expect(result.visible).to be_empty
    expect(result.just_dismissed).to be_empty
  end

  it "flags the weekend calorie leak from recent habits" do
    travel_to Time.zone.local(2026, 9, 5, 10, 0, 0) do
      (Date.new(2026, 8, 31)..Date.new(2026, 9, 4)).each do |date|
        log_day(date, calories: 1700)
      end
      log_day(Date.new(2026, 8, 29), calories: 2500)
      log_day(Date.new(2026, 8, 30), calories: 2400)
      today = DailyLog.for_date(saturday)

      result = described_class.call(goal: goal, today: today, now: Time.current)

      expect(result.visible.map(&:key)).to include("weekend_leak")
      expect(result.visible.first.title).to eq("Weekends are the leak")
    end
  end

  it "suggests not eating the run twice on a typical run weekday" do
    travel_to Time.zone.local(2026, 9, 2, 8, 0, 0) do
      log_day(Date.new(2026, 8, 19), calories: 1700, run_km: 12)
      log_day(Date.new(2026, 8, 26), calories: 1700, run_km: 11)
      today = DailyLog.for_date(Date.new(2026, 9, 2))

      result = described_class.call(goal: goal, today: today, now: Time.current)

      expect(result.visible.map(&:key)).to include("dont_eat_back")
    end
  end

  it "calls out tray-sized treats" do
    travel_to Time.zone.local(2026, 9, 3, 12, 0, 0) do
      log_day(Date.new(2026, 9, 1), calories: 1600)
      log_day(Date.new(2026, 9, 2), calories: 1443, meal_name: "Nora Cooks oil-free walnut brownies (cupcakes)")
      today = DailyLog.for_date(Date.new(2026, 9, 3))

      result = described_class.call(goal: goal, today: today, now: Time.current)

      expect(result.visible.map(&:key)).to include("treat_serving")
      expect(result.visible.find { |s| s.key == "treat_serving" }.body).to include("1443")
    end
  end

  it "hides a dismissed nudge for a week, then can mark it not helpful" do
    travel_to Time.zone.local(2026, 9, 5, 10, 0, 0) do
      (Date.new(2026, 8, 31)..Date.new(2026, 9, 4)).each { |date| log_day(date, calories: 1700) }
      log_day(Date.new(2026, 8, 29), calories: 2500)
      log_day(Date.new(2026, 8, 30), calories: 2400)
      today = DailyLog.for_date(saturday)

      HabitSuggestionFeedback.find_or_initialize_by(suggestion_key: "weekend_leak").dismiss!

      result = described_class.call(goal: goal, today: today, now: Time.current)
      expect(result.visible.map(&:key)).not_to include("weekend_leak")
      expect(result.just_dismissed.map(&:key)).to include("weekend_leak")
    end
  end

  it "never shows a key marked not helpful" do
    travel_to Time.zone.local(2026, 9, 5, 10, 0, 0) do
      (Date.new(2026, 8, 31)..Date.new(2026, 9, 4)).each { |date| log_day(date, calories: 1700) }
      log_day(Date.new(2026, 8, 29), calories: 2500)
      log_day(Date.new(2026, 8, 30), calories: 2400)
      HabitSuggestionFeedback.find_or_initialize_by(suggestion_key: "weekend_leak").mark_not_helpful!

      result = described_class.call(goal: goal, today: DailyLog.for_date(saturday), now: Time.current)
      expect(result.visible.map(&:key)).not_to include("weekend_leak")
      expect(result.just_dismissed.map(&:key)).not_to include("weekend_leak")
    end
  end
end
