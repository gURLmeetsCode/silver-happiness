# frozen_string_literal: true

require "test_helper"

class DailyLogCaloriesTest < ActiveSupport::TestCase
  test "includes strength session calories in burned total" do
    log = DailyLog.create!(logged_on: Date.new(2026, 8, 8))
    log.workouts.create!(activity_type: :run, calories_burned: 448, distance_km: 8)
    log.strength_sessions.create!(location: :gym, calories_burned: 185, duration_min: 45)

    assert_equal 633, log.calories_burned
    assert_includes log.calories_burned_breakdown.map { |p| p[:label] }, "Strength session"
  end

  test "includes edit-form run calories alongside strength session" do
    log = DailyLog.create!(logged_on: Date.new(2026, 8, 9), run_km: 8, run_calories: 448)
    log.strength_sessions.create!(location: :gym, calories_burned: 185, duration_min: 45)

    assert_equal 633, log.calories_burned
    assert_includes log.calories_burned_breakdown.map { |p| p[:label] }, "Run"
  end

  test "does not double-count run calories when workout record exists" do
    log = DailyLog.create!(logged_on: Date.new(2026, 8, 10), run_calories: 999)
    log.workouts.create!(activity_type: :run, calories_burned: 448, distance_km: 8)

    assert_equal 448, log.calories_burned
  end

  test "sleep window labels previous evening to wake morning" do
    log = DailyLog.create!(
      logged_on: Date.new(2026, 8, 8),
      bed_time: Time.zone.parse("22:30"),
      wake_time: Time.zone.parse("06:15")
    )

    assert_equal "Fri 22:30 → Sat 06:15", log.sleep_window_label
    assert_match(/7\.8h/, log.sleep_summary)
  end
end
