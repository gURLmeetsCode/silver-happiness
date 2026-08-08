# frozen_string_literal: true

require "test_helper"

class DailyLogsControllerTest < ActionDispatch::IntegrationTest
  test "update saves run calories from edit form" do
    log = DailyLog.create!(logged_on: Date.new(2026, 8, 12))

    patch daily_log_path(log), params: {
      daily_log: {
        run_km: 8,
        run_calories: 448,
        walk_km: "",
        walk_calories: ""
      }
    }

    assert_redirected_to daily_log_path(log)
    log.reload
    assert_equal 448, log.run_calories
    assert_equal 8, log.run_km.to_i
    assert_equal 448, log.workouts.activity_type_run.first.calories_burned
  end
end
