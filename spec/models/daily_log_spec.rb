# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyLog do
  describe "calories burned" do
    it "includes strength session calories in the burned total" do
      log = create(:daily_log)
      log.workouts.create!(activity_type: :run, calories_burned: 448, distance_km: 8)
      log.strength_sessions.create!(location: :gym, calories_burned: 185, duration_min: 45)

      expect(log.calories_burned).to eq(633)
      expect(log.calories_burned_breakdown.map { |p| p[:label] }).to include("Strength session")
    end

    it "includes edit-form run calories alongside a strength session" do
      log = create(:daily_log, :with_run)
      log.strength_sessions.create!(location: :gym, calories_burned: 185, duration_min: 45)

      expect(log.calories_burned).to eq(633)
      expect(log.calories_burned_breakdown.map { |p| p[:label] }).to include("Run")
    end

    it "does not double-count a stale run_calories column when a run workout exists" do
      log = create(:daily_log)
      log.workouts.create!(activity_type: :run, calories_burned: 448, distance_km: 8)
      log.update_column(:run_calories, 999)

      expect(log.reload.calories_burned).to eq(448)
    end

    it "updates the existing run workout instead of adding another" do
      log = create(:daily_log, :with_run)
      expect(log.workouts.activity_type_run.count).to eq(1)

      log.update!(run_calories: 500)

      expect(log.workouts.activity_type_run.count).to eq(1)
      expect(log.calories_burned).to eq(500)
    end

    it "removes the run workout when run details are cleared" do
      log = create(:daily_log, :with_run)
      log.update!(run_km: nil, run_calories: nil)

      expect(log.workouts.activity_type_run.count).to eq(0)
      expect(log.calories_burned).to eq(0)
    end
  end

  describe "sleep" do
    it "labels the window from the previous evening to the wake morning" do
      log = create(:daily_log, :with_sleep, logged_on: Date.new(2026, 8, 8))

      expect(log.sleep_window_label).to eq("Fri 22:30 → Sat 06:15")
      expect(log.sleep_summary).to match(/7\.8h/)
    end

    it "returns nil when either end of the window is missing" do
      log = create(:daily_log, bed_time: Time.zone.parse("22:30"))

      expect(log.sleep_duration_hours).to be_nil
      expect(log.sleep_summary).to be_nil
    end
  end

  describe "water" do
    it "adds water to the running total" do
      log = create(:daily_log, water_ml: 250)
      log.add_water!(500)

      expect(log.reload.water_ml).to eq(750)
    end

    it "reports glasses as quarter litres" do
      expect(create(:daily_log, water_ml: 500).water_glasses).to eq(2.0)
    end
  end

  describe ".for_date" do
    it "finds or creates a log for the date" do
      date = Date.new(2026, 3, 3)

      expect { DailyLog.for_date(date) }.to change(DailyLog, :count).by(1)
      expect { DailyLog.for_date(date) }.not_to change(DailyLog, :count)
    end
  end

  describe "totals" do
    it "sums macros across meal entries" do
      log = create(:daily_log)
      create(:meal_entry, daily_log: log, calories: 300, protein_g: 20, carbs_g: 30, fat_g: 10)
      create(:meal_entry, daily_log: log, calories: 200, protein_g: 15, carbs_g: 20, fat_g: 5)

      expect(log.total_calories).to eq(500)
      expect(log.total_protein).to eq(35)
      expect(log.total_carbs).to eq(50)
      expect(log.total_fat).to eq(15)
    end
  end
end
