# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Daily logs", type: :request do
  before { Goal.current }

  describe "GET /daily_logs" do
    it "lists this week and the focus month" do
      create(:daily_log, logged_on: Date.current)
      create(:daily_log, logged_on: Date.current.beginning_of_month)

      get daily_logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This week")
      expect(response.body).to include(Date.current.strftime("%B %Y"))
    end

    it "paginates older months" do
      older = Date.current.beginning_of_month - 1.month
      create(:daily_log, logged_on: older + 2.days)

      get daily_logs_path(month: older.strftime("%Y-%m"))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(older.strftime("%B %Y"))
    end
  end

  describe "GET /daily_logs/:id" do
    it "renders the day page" do
      log = create(:daily_log)
      create(:meal_entry, daily_log: log)
      create(:strength_session, daily_log: log)
      create(:quick_product)
      create(:beverage_product)

      get daily_log_path(log)

      expect(response).to have_http_status(:ok)
    end

    it "accepts the 'today' shortcut id" do
      get daily_log_path(id: "today")

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for an unknown log" do
      get daily_log_path(id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /daily_logs/:id/edit" do
    it "renders the check-in form" do
      get edit_daily_log_path(create(:daily_log))

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /daily_logs/:id" do
    it "saves run calories and syncs the run workout" do
      log = create(:daily_log)

      patch daily_log_path(log), params: {
        daily_log: { run_km: 8, run_calories: 448, walk_km: "", walk_calories: "" }
      }

      expect(response).to redirect_to(daily_log_path(log))
      log.reload
      expect(log.run_calories).to eq(448)
      expect(log.run_km.to_i).to eq(8)
      expect(log.workouts.activity_type_run.first.calories_burned).to eq(448)
    end

    it "saves weight and sleep details" do
      log = create(:daily_log)

      patch daily_log_path(log), params: {
        daily_log: {
          weight_kg: 60.4,
          bed_time: "22:30",
          wake_time: "06:15",
          sleep_quality: 8,
          feeling_check_in: "Good energy"
        }
      }

      log.reload
      expect(log.weight_kg).to eq(60.4)
      expect(log.sleep_quality).to eq(8)
      expect(log.feeling_check_in).to eq("Good energy")
    end
  end

  describe "GET /today" do
    it "redirects to today's log" do
      get today_path

      expect(response).to redirect_to(daily_log_path(DailyLog.today))
    end
  end

  describe "POST /daily_logs/:id/copy_meals" do
    it "copies meals from the source day" do
      source = create(:daily_log, logged_on: Date.current - 1.day)
      create(:meal_entry, daily_log: source, name: "Oats")
      target = create(:daily_log, logged_on: Date.current)

      post copy_meals_daily_log_path(target), params: { source_id: source.id }

      expect(response).to redirect_to(daily_log_path(target))
      expect(target.reload.meal_entries.map(&:name)).to eq([ "Oats" ])
    end

    # Copying used to wipe the day first, which would silently delete meals
    # already logged before the button was pressed.
    it "keeps meals already logged on the target day" do
      source = create(:daily_log, logged_on: Date.current - 1.day)
      create(:meal_entry, daily_log: source, name: "Oats", meal_type: :breakfast)
      target = create(:daily_log, logged_on: Date.current)
      mine = create(:meal_entry, daily_log: target, name: "My own lunch",
                    meal_type: :lunch, calories: 640)

      post copy_meals_daily_log_path(target), params: { source_id: source.id }

      expect(target.reload.meal_entries.map(&:name)).to contain_exactly("My own lunch", "Oats")
      expect(mine.reload.calories).to eq(640)
    end

    it "does not duplicate a meal that is already there" do
      source = create(:daily_log, logged_on: Date.current - 1.day)
      create(:meal_entry, daily_log: source, name: "Oats", meal_type: :breakfast)
      target = create(:daily_log, logged_on: Date.current)
      create(:meal_entry, daily_log: target, name: "Oats", meal_type: :breakfast)

      expect {
        post copy_meals_daily_log_path(target), params: { source_id: source.id }
      }.not_to change { target.reload.meal_entries.count }

      expect(flash[:notice]).to match(/Nothing new to copy/)
    end

    it "reports how many meals were added" do
      source = create(:daily_log, logged_on: Date.current - 1.day)
      create(:meal_entry, daily_log: source, name: "Oats", meal_type: :breakfast)
      create(:meal_entry, daily_log: source, name: "Salad", meal_type: :lunch)
      target = create(:daily_log, logged_on: Date.current)

      post copy_meals_daily_log_path(target), params: { source_id: source.id }

      expect(flash[:notice]).to match(/Added 2 meals/)
    end

    it "returns 404 when the source day does not exist" do
      post copy_meals_daily_log_path(create(:daily_log)), params: { source_id: 999_999 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /daily_logs/:id/add_water" do
    it "adds the requested amount" do
      log = create(:daily_log, water_ml: 250)

      post add_water_daily_log_path(log), params: { amount_ml: 500 }

      expect(response).to redirect_to(daily_log_path(log))
      expect(log.reload.water_ml).to eq(750)
    end

    it "falls back to 250 ml when the amount is missing or zero" do
      log = create(:daily_log, water_ml: 0)

      post add_water_daily_log_path(log), params: { amount_ml: 0 }

      expect(log.reload.water_ml).to eq(250)
    end
  end

  describe "POST /daily_logs/:id/set_water" do
    it "overwrites the total" do
      log = create(:daily_log, water_ml: 1000)

      post set_water_daily_log_path(log), params: { amount_ml: 400 }

      expect(log.reload.water_ml).to eq(400)
    end

    it "clamps negatives to zero" do
      log = create(:daily_log, water_ml: 1000)

      post set_water_daily_log_path(log), params: { amount_ml: -50 }

      expect(log.reload.water_ml).to eq(0)
    end
  end

  describe "decimal distance and weight" do
    it "accepts precise run distance and weight decimals" do
      log = DailyLog.today

      patch daily_log_path(log), params: {
        daily_log: { run_km: "5.24", weight_kg: "58.60" },
        return_to: daily_log_path(log, anchor: "movement")
      }

      log.reload
      expect(log.run_km).to eq(5.24)
      expect(log.weight_kg).to eq(58.60)
    end

    it "shows number fields that allow any decimal step" do
      get daily_log_path(DailyLog.today)

      expect(response.body).to include('name="daily_log[run_km]"')
      expect(response.body).to include('step="any"')
      expect(response.body).to include('name="daily_log[weight_kg]"')
    end
  end

  describe "day markers and resting burn" do
    it "can mark a hard / compulsive eating day" do
      log = DailyLog.today

      patch daily_log_path(log), params: {
        daily_log: { compulsive_eating_day: "1" },
        return_to: daily_log_path(log, anchor: "body")
      }

      expect(log.reload).to be_compulsive_eating_day

      get daily_log_path(log)
      expect(response.body).to include("Hard eating day")
    end

    it "saves a hard-day debrief with the check-in" do
      log = DailyLog.today

      patch daily_log_path(log), params: {
        daily_log: {
          compulsive_eating_day: "1",
          hard_day_trigger: "Bulk bags open after a stressful afternoon",
          hard_day_what_was_available: "Yoonuts and nuts",
          hard_day_next_time: "Portion into a bowl and use urge pause"
        },
        return_to: daily_log_path(log, anchor: "body")
      }

      log.reload
      expect(log).to be_hard_day_debrief
      expect(log.hard_day_trigger).to include("Bulk bags")
      expect(log.hard_day_next_time).to include("urge pause")
    end

    it "shows resting burn (BMR) as a caption when the body profile is set" do
      Goal.current.update!(height_cm: 163, age_years: 37, sex: "female", starting_weight_kg: 59.5)
      get daily_log_path(DailyLog.today)

      expect(response.body).to include("Just staying alive uses")
      expect(response.body).to include("BMR")
    end
  end
end
