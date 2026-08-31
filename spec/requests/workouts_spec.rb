# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workouts", type: :request do
  before { Goal.current }

  let(:log) { create(:daily_log) }

  describe "POST /daily_logs/:daily_log_id/workouts" do
    it "logs a non-run/walk workout on the workouts table" do
      post daily_log_workouts_path(log), params: {
        workout: { activity_type: "other", distance_km: 1.0, calories_burned: 80, notes: "Yoga" }
      }

      expect(response).to redirect_to(daily_log_path(log, anchor: "movement"))
      expect(log.workouts.last).to have_attributes(
        activity_type: "other",
        calories_burned: 80,
        notes: "Yoga"
      )
    end

    it "saves a walk through daily log fields so a later day save keeps the calories" do
      post daily_log_workouts_path(log), params: {
        workout: { activity_type: "walk", distance_km: 3.2, calories_burned: 120, notes: "Evening walk" }
      }

      expect(response).to redirect_to(daily_log_path(log, anchor: "movement"))
      log.reload
      expect(log.walk_calories).to eq(120)
      expect(log.walk_km).to eq(3.2)
      expect(log.workouts.activity_type_walk.sole.calories_burned).to eq(120)
      expect(log.calories_burned).to eq(120)

      # Saving weight (or any other day field) used to wipe Other-workouts walks.
      patch daily_log_path(log), params: {
        daily_log: { weight_kg: 58.2, walk_km: log.walk_km, walk_calories: log.walk_calories }
      }

      log.reload
      expect(log.workouts.activity_type_walk.sole.calories_burned).to eq(120)
      expect(log.calories_burned).to eq(120)
    end

    it "keeps walk calories after a run-only save that leaves walk fields intact" do
      post daily_log_workouts_path(log), params: {
        workout: { activity_type: "walk", calories_burned: 159 }
      }
      log.reload

      patch daily_log_path(log), params: {
        daily_log: {
          run_km: 8,
          run_calories: 448,
          walk_km: log.walk_km,
          walk_calories: log.walk_calories
        }
      }

      log.reload
      expect(log.workouts.activity_type_walk.sole.calories_burned).to eq(159)
      expect(log.workouts.activity_type_run.sole.calories_burned).to eq(448)
      expect(log.calories_burned).to eq(159 + 448)
    end

    it "redirects back when the workout is invalid" do
      post daily_log_workouts_path(log), params: {
        workout: { activity_type: "other", calories_burned: -5 }
      }

      expect(response).to redirect_to(daily_log_path(log, anchor: "movement"))
      expect(log.workouts.count).to eq(0)
    end
  end

  describe "DELETE /daily_logs/:daily_log_id/workouts/:id" do
    it "removes a non-run/walk workout" do
      workout = create(:workout, daily_log: log, activity_type: :other, calories_burned: 50)

      delete daily_log_workout_path(log, workout)

      expect(response).to redirect_to(daily_log_path(log, anchor: "movement"))
      expect(Workout.exists?(workout.id)).to be false
    end

    it "clears walk fields when removing a synced walk" do
      log.update!(walk_km: 2.5, walk_calories: 100)
      walk = log.workouts.activity_type_walk.sole

      delete daily_log_workout_path(log, walk)

      log.reload
      expect(log.walk_calories).to be_nil
      expect(log.workouts.activity_type_walk).to be_none
    end
  end
end
