# frozen_string_literal: true

require "rails_helper"

# The redesign moves inputs between pages. Every field the app can record must
# stay reachable from some screen, so a layout change can never quietly drop a
# thing you used to be able to log.
RSpec.describe "Data capture coverage", type: :request do
  before do
    Goal.current
    create(:product)
    create(:beverage_product)
    create(:meal_template, :with_items)
    create(:workout_plan, :with_exercises)
  end

  let(:today) { DailyLog.today }

  describe "the day log offers every DailyLog field" do
    # Every column a person fills in by hand, and the form field name that
    # captures it.
    {
      "weight_kg" => "daily_log[weight_kg]",
      "weight_pre_run" => "daily_log[weight_pre_run]",
      "run_km" => "daily_log[run_km]",
      "run_calories" => "daily_log[run_calories]",
      "walk_km" => "daily_log[walk_km]",
      "walk_calories" => "daily_log[walk_calories]",
      "training_notes" => "daily_log[training_notes]",
      "energy_notes" => "daily_log[energy_notes]",
      "notes" => "daily_log[notes]",
      "on_period" => "daily_log[on_period]",
      "compulsive_eating_day" => "daily_log[compulsive_eating_day]",
      "bed_time" => "daily_log[bed_time]",
      "wake_time" => "daily_log[wake_time]",
      "sleep_quality" => "daily_log[sleep_quality]",
      "feeling_check_in" => "daily_log[feeling_check_in]",
      "hard_day_trigger" => "daily_log[hard_day_trigger]",
      "hard_day_what_was_available" => "daily_log[hard_day_what_was_available]",
      "hard_day_next_time" => "daily_log[hard_day_next_time]"
    }.each do |column, field|
      it "has an input for #{column}" do
        get daily_log_path(today)

        expect(response.body).to include(field)
      end
    end
  end

  describe "the day log offers every way to add a meal" do
    it "has the custom meal form" do
      get daily_log_path(today)

      expect(response.body).to include("meal_entry[name]")
      expect(response.body).to include("meal_entry[calories]")
      expect(response.body).to include("meal_entry[protein_g]")
      expect(response.body).to include("meal_entry[carbs_g]")
      expect(response.body).to include("meal_entry[fat_g]")
      expect(response.body).to include("meal_entry[notes]")
    end

    it "has the meal builder, with an amount and a unit per item" do
      get daily_log_path(today)

      expect(response.body).to include("items[0][picker]")
      expect(response.body).to include("items[0][quantity]")
      expect(response.body).to include("items[0][unit]")
    end

    it "has copy-from-yesterday and meal builder (no usual/quick-add strip)" do
      get daily_log_path(today)

      expect(response.body).to include("Build a meal")
      expect(response.body).not_to include("Usual ·")
      expect(response.body).not_to include("Quick add beverage")
      expect(response.body).not_to include("Quick add snack")
      expect(response.body).not_to include("Quick templates")
    end
  end

  describe "the day log offers movement and body inputs" do
    it "has the workout form" do
      get daily_log_path(today)

      expect(response.body).to include("workout[activity_type]")
      expect(response.body).to include("workout[distance_km]")
      expect(response.body).to include("workout[calories_burned]")
      expect(response.body).to include("workout[notes]")
    end

    it "links to strength session logging" do
      get daily_log_path(today)

      expect(response.body).to include(new_daily_log_strength_session_path(today))
    end

    it "has water controls" do
      get daily_log_path(today)

      expect(response.body).to include(add_water_daily_log_path(today))
      expect(response.body).to include(set_water_daily_log_path(today))
      expect(response.body).to include("+ 250 ml")
      expect(response.body).to include("Set Volvic bottle level")
    end
    it "links to the urge pause flow" do
      get daily_log_path(today)

      expect(response.body).to include(new_daily_log_urge_check_in_path(today))
      expect(response.body).to include("I’m about to spiral")
    end
  end

  describe "the day log offers photo capture" do
    it "has the progress photo form with type and caption" do
      get daily_log_path(today)

      expect(response.body).to include("progress_photo[image]")
      expect(response.body).to include("progress_photo[photo_type]")
      expect(response.body).to include("progress_photo[caption]")
    end

    it "links to every outfit category" do
      get daily_log_path(today)

      OutfitPhoto.categories.each_key do |category|
        expect(response.body).to include("category=#{category}"),
          "no link to log a #{category} outfit photo"
      end
    end
  end

  describe "deep links from the home screen" do
    it "resolves the meals anchor" do
      get daily_log_path(today, anchor: "meals")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="meals"')
    end

    it "resolves the water anchor" do
      get daily_log_path(today, anchor: "water")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="water"')
    end
  end

  describe "the edit page still accepts the full day" do
    it "keeps every field on one form" do
      get edit_daily_log_path(today)

      %w[weight_kg run_km walk_km training_notes energy_notes notes on_period
         compulsive_eating_day water_ml bed_time wake_time sleep_quality feeling_check_in
         hard_day_trigger hard_day_what_was_available hard_day_next_time].each do |column|
        expect(response.body).to include("daily_log[#{column}]"),
          "edit page lost the #{column} field"
      end
    end
  end
end
