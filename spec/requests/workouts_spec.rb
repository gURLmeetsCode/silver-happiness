# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workouts", type: :request do
  before { Goal.current }

  let(:log) { create(:daily_log) }

  describe "POST /daily_logs/:daily_log_id/workouts" do
    it "logs a workout" do
      post daily_log_workouts_path(log), params: {
        workout: { activity_type: "walk", distance_km: 3.2, calories_burned: 120, notes: "Evening walk" }
      }

      expect(response).to redirect_to(daily_log_path(log))
      expect(log.workouts.last.calories_burned).to eq(120)
    end

    it "redirects back when the workout is invalid" do
      post daily_log_workouts_path(log), params: {
        workout: { activity_type: "walk", calories_burned: -5 }
      }

      expect(response).to redirect_to(daily_log_path(log))
      expect(log.workouts.count).to eq(0)
    end
  end

  describe "DELETE /daily_logs/:daily_log_id/workouts/:id" do
    it "removes the workout" do
      workout = create(:workout, daily_log: log)

      delete daily_log_workout_path(log, workout)

      expect(response).to redirect_to(daily_log_path(log))
      expect(Workout.exists?(workout.id)).to be false
    end
  end
end
