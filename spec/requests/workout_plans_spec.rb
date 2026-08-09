# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workout plans", type: :request do
  describe "GET /workout_plans" do
    it "lists the plans" do
      plan = create(:workout_plan, :with_exercises)

      get workout_plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.name)
    end

    it "renders with no plans at all" do
      get workout_plans_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /workout_plans/:id" do
    it "shows a plan and its exercises" do
      plan = create(:workout_plan, :with_exercises)

      get workout_plan_path(plan)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plan.name)
    end

    it "returns 404 for an unknown plan" do
      get workout_plan_path(id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end
end
