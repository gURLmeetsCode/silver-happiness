# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /metrics" do
    it "renders with no data" do
      get metrics_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the weekly summary and charts" do
      Goal.current
      7.times { |n| create(:daily_log, logged_on: Date.current - n.days, weight_kg: 60 + n) }
      create(:meal_entry, daily_log: DailyLog.today, calories: 500, protein_g: 30)
      create(:strength_session, daily_log: DailyLog.today)

      get metrics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This week")
      expect(response.body).to include("Weight vs target")
      expect(response.body).to include("Cycle &amp; the scale")
      expect(response.body).to include("Calorie deficit this week")
      expect(response.body).to include("Cumulative deficit vs plan")
    end

    it "marks period context on weight when today is a period day" do
      Goal.current
      create(:daily_log, logged_on: Date.current, weight_kg: 58.2, on_period: true)

      get metrics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Period day")
      expect(response.body).to include("Scale may be up from water")
    end
  end
end
