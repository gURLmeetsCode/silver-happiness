# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklySummary do
  let!(:goal) do
    Goal.current.update!(
      height_cm: 163, age_years: 37, sex: "female",
      activity_level: "moderate", starting_weight_kg: 59.5,
      target_deficit_kcal: 400
    )
    Goal.current
  end

  it "projects weekly loss from the cumulative deficit" do
    # Maintenance is ~1,965. Eating 1,565 each day is a 400 kcal deficit.
    create(:daily_log, logged_on: Date.current.beginning_of_week, weight_kg: 59.5)
    create(:daily_log, logged_on: Date.current.beginning_of_week + 1)
    DailyLog.find_by!(logged_on: Date.current.beginning_of_week).tap do |log|
      create(:meal_entry, daily_log: log, calories: 1565, protein_g: 90)
    end
    DailyLog.find_by!(logged_on: Date.current.beginning_of_week + 1).tap do |log|
      create(:meal_entry, daily_log: log, calories: 1565, protein_g: 90)
    end

    week = described_class.new(Date.current.beginning_of_week)

    expect(week).to be_deficit_ready
    expect(week.week_deficit_kcal).to eq(800)
    expect(week.projected_week_loss_kg).to eq(0.1)
    expect(week.planned_week_loss_kg).to eq(0.1)
    expect(week.deficit_pace_status).to eq(:on_target)
    expect(week.cumulative_deficit_by_day.map(&:last)).to eq([ 400, 800 ])
  end

  it "marks the pace behind when eating above the planned deficit" do
    create(:daily_log, logged_on: Date.current.beginning_of_week, weight_kg: 59.5)
    log = DailyLog.find_by!(logged_on: Date.current.beginning_of_week)
    create(:meal_entry, daily_log: log, calories: 2200, protein_g: 90)

    week = described_class.new(Date.current.beginning_of_week)

    expect(week.week_deficit_kcal).to be < 0
    expect(week.deficit_pace_status).to eq(:above_target)
  end
end
