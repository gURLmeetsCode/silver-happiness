# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Strength sessions", type: :request do
  let(:log) { create(:daily_log) }

  describe "GET /daily_logs/:daily_log_id/strength_sessions/new" do
    it "renders a blank session form" do
      get new_daily_log_strength_session_path(log)

      expect(response).to have_http_status(:ok)
    end

    it "prefills from a workout plan" do
      plan = create(:workout_plan, :with_exercises)

      get new_daily_log_strength_session_path(log, workout_plan_id: plan.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.workout_plan_exercises.first.name)
    end

    it "returns 404 for an unknown plan" do
      get new_daily_log_strength_session_path(log, workout_plan_id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /daily_logs/:daily_log_id/strength_sessions" do
    it "creates a session with exercise logs" do
      post daily_log_strength_sessions_path(log), params: {
        strength_session: {
          location: "gym",
          perceived_difficulty: 6,
          duration_min: 45,
          calories_burned: 185,
          strength_exercise_logs_attributes: {
            "0" => { name: "Squat", sets: 3, reps: "10", weight_kg: 20 }
          }
        }
      }

      session = log.strength_sessions.last
      expect(response).to redirect_to(daily_log_strength_session_path(log, session))
      expect(session.strength_exercise_logs.map(&:name)).to eq([ "Squat" ])
    end

    it "re-renders with 422 when the difficulty is out of range" do
      post daily_log_strength_sessions_path(log), params: {
        strength_session: { location: "gym", perceived_difficulty: 42 }
      }

      expect(response).to have_http_status(422)
    end
  end

  describe "GET /daily_logs/:daily_log_id/strength_sessions/:id" do
    it "shows the session" do
      session = create(:strength_session, :with_logs, daily_log: log)

      get daily_log_strength_session_path(log, session)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a session on another day" do
      other = create(:strength_session, daily_log: create(:daily_log))

      get daily_log_strength_session_path(log, other)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /daily_logs/:daily_log_id/strength_sessions/:id/edit" do
    it "renders the edit form" do
      session = create(:strength_session, :with_logs, daily_log: log)

      get edit_daily_log_strength_session_path(log, session)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /daily_logs/:daily_log_id/strength_sessions/:id" do
    it "updates the session" do
      session = create(:strength_session, daily_log: log)

      patch daily_log_strength_session_path(log, session), params: {
        strength_session: { duration_min: 60, calories_burned: 220 }
      }

      expect(response).to redirect_to(daily_log_strength_session_path(log, session))
      expect(session.reload.duration_min).to eq(60)
    end

    it "re-renders with 422 when invalid" do
      session = create(:strength_session, daily_log: log)

      patch daily_log_strength_session_path(log, session), params: {
        strength_session: { perceived_difficulty: 99 }
      }

      expect(response).to have_http_status(422)
    end
  end

  describe "DELETE /daily_logs/:daily_log_id/strength_sessions/:id" do
    it "removes the session" do
      session = create(:strength_session, daily_log: log)

      delete daily_log_strength_session_path(log, session)

      expect(response).to redirect_to(daily_log_path(log))
      expect(StrengthSession.exists?(session.id)).to be false
    end
  end
end
