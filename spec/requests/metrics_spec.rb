# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /metrics" do
    it "renders with no data" do
      get metrics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Export PDF")
      expect(response.body).to include("What the data says")
    end

    it "shows the weekly summary and charts" do
      Goal.current
      7.times { |n| create(:daily_log, logged_on: Date.current - n.days, weight_kg: 60 + n) }
      create(:meal_entry, daily_log: DailyLog.today, calories: 500, protein_g: 30)
      create(:strength_session, daily_log: DailyLog.today)

      get metrics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This week")
      expect(response.body).to include("Cycle &amp; the scale")
      expect(response.body).to include("Calorie deficit this week")
      expect(response.body).to include("Cumulative deficit vs plan")
    end

    it "shows trend patterns when enough history exists" do
      Goal.current
      travel_to Time.zone.local(2026, 9, 5, 12, 0, 0) do
        (Date.new(2026, 8, 24)..Date.new(2026, 9, 4)).each_with_index do |date, i|
          log = DailyLog.find_or_create_by!(logged_on: date)
          weekend = date.saturday? || date.sunday?
          log.update!(weight_kg: 58.0 - (i * 0.04))
          create(:meal_entry, daily_log: log, calories: weekend ? 2500 : 1700, name: weekend ? "Weekend" : "Weekday")
        end

        get metrics_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("What the data says")
        expect(response.body).to include("Weekday / weekend")
        expect(response.body).to include("7-day avg weight")
        expect(response.body).to include("Weight + 7-day rolling average")
      end
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

  describe "GET /metrics/export" do
    it "downloads a PDF report" do
      Goal.current
      create(:daily_log, logged_on: Date.current, weight_kg: 57.5)
      create(:meal_entry, daily_log: DailyLog.today, calories: 1600, protein_g: 90)

      get export_metrics_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.body).to start_with("%PDF")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("silver-happiness-metrics-")
    end
  end
end
