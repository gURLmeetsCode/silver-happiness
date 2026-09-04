# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders for a brand new install with no data" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "greets by name once one is set" do
      Goal.current.update!(display_name: "Natasha")

      get root_path

      expect(response.body).to include("Natasha")
    end

    it "greets without a name when none is set" do
      Goal.current.update!(display_name: nil)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/Good morning|Good afternoon|Good evening|Still up/)
    end

    it "offers inline weight and sleep logging" do
      get root_path

      expect(response.body).to include("daily_log[weight_kg]")
      expect(response.body).to include("daily_log[bed_time]")
      expect(response.body).to include("daily_log[wake_time]")
      expect(response.body).to include("daily_log[sleep_quality]")
    end

    it "shows cut status and one-tap water on home" do
      today = DailyLog.today
      today.update!(water_ml: 500)
      today.meal_entries.create!(name: "Toast", meal_type: :breakfast, calories: 200, protein_g: 8)

      get root_path

      expect(response.body).to include("Today’s cut")
      expect(response.body).to include("500 ml")
      expect(response.body).to include("ml to goal")
      expect(response.body).to include("+ 250 ml")
      expect(response.body).to include(add_water_daily_log_path(today))
      expect(response.body).to include('name="amount_ml"')
      expect(response.body).to include(metrics_path)
    end

    it "links to meals and metrics from home shortcuts" do
      get root_path
      today = DailyLog.today

      expect(response.body).to include("#{daily_log_path(today)}#meals")
      expect(response.body).to include("#{daily_log_path(today)}#water")
      expect(response.body).to include(metrics_path)
    end

    # The home screen used to render every chart and quick-add button; keeping
    # it lean is the point of the redesign.
    it "does not render weekly charts" do
      create(:daily_log, logged_on: Date.current, weight_kg: 60)

      get root_path

      expect(response.body).not_to include("This week")
      expect(response.body).not_to include("Calories eaten vs burned vs target")
    end

    it "shows daily outfit inspo when outfit photos exist" do
      create(:outfit_photo, caption: "Mirror moment", category: :feeling_cute)

      get root_path

      expect(response.body).to include("Daily inspo")
      expect(response.body).to include("Mirror moment")
      expect(response.body).to include("Feeling cute")
      expect(response.body).to include(outfit_photos_path)
      expect(response.body).to include("<img")
    end

    it "omits daily inspo when there are no outfit photos" do
      get root_path

      expect(response.body).not_to include("Daily inspo")
    end

    it "shows cut nudges from weekend eating habits" do
      travel_to Time.zone.local(2026, 9, 5, 10, 0, 0) do
        (Date.new(2026, 8, 31)..Date.new(2026, 9, 4)).each do |date|
          log = DailyLog.find_or_create_by!(logged_on: date)
          create(:meal_entry, daily_log: log, calories: 1700, name: "Weekday meals")
        end
        [ Date.new(2026, 8, 29), Date.new(2026, 8, 30) ].each do |date|
          log = DailyLog.find_or_create_by!(logged_on: date)
          create(:meal_entry, daily_log: log, calories: 2500, name: "Weekend meals")
        end

        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("For the cut")
        expect(response.body).to include("Weekends are the leak")
        expect(response.body).to include("Dismiss")
        expect(response.body).to include("Not helpful")
      end
    end
  end

  describe "GET /dashboard" do
    it "renders the same page" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "logging weight from home" do
    it "saves the weight and returns home" do
      today = DailyLog.today

      patch daily_log_path(today), params: {
        daily_log: { weight_kg: 60.2 }, return_to: root_path
      }

      expect(response).to redirect_to(root_path)
      expect(today.reload.weight_kg).to eq(60.2)
    end

    it "saves sleep details and returns home" do
      today = DailyLog.today

      patch daily_log_path(today), params: {
        daily_log: { bed_time: "22:30", wake_time: "06:15", sleep_quality: 8 },
        return_to: root_path
      }

      expect(response).to redirect_to(root_path)
      expect(today.reload.sleep_quality).to eq(8)
    end

    it "ignores an off-site return_to" do
      today = DailyLog.today

      patch daily_log_path(today), params: {
        daily_log: { weight_kg: 60.2 }, return_to: "//evil.example.com"
      }

      expect(response).to redirect_to(daily_log_path(today))
    end

    it "ignores an absolute external return_to" do
      today = DailyLog.today

      patch daily_log_path(today), params: {
        daily_log: { weight_kg: 60.2 }, return_to: "https://evil.example.com"
      }

      expect(response).to redirect_to(daily_log_path(today))
    end
  end
end
