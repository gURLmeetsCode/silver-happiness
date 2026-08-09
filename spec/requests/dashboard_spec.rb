# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "renders for a brand new install with no data" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "renders with a full week of data" do
      Goal.current
      7.times { |n| create(:daily_log, logged_on: Date.current - n.days, weight_kg: 60 + n) }
      create(:meal_entry, daily_log: DailyLog.today)
      create(:quick_product)
      create(:beverage_product)
      create(:workout_plan, :with_exercises)

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /dashboard" do
    it "renders the same page" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
    end
  end
end
