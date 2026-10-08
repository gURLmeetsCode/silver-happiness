# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/home_strength_plans")

RSpec.describe HomeStrengthPlans do
  it "replaces the old toning plans with the home back-of-body plans" do
    old = WorkoutPlan.create!(slug: "monday-home-toning", name: "Monday home toning",
      location: :home, plan_kind: :supplemental_full, suggested_wday: 1)
    old.workout_plan_exercises.create!(name: "Push-ups", position: 0)
    runna = WorkoutPlan.create!(slug: "wednesday-home", name: "Wednesday home strength (Runna)",
      location: :home, plan_kind: :runna_reference, scheduled_wday: 3)

    described_class.install!

    expect(WorkoutPlan.exists?(old.id)).to be(false)
    expect(WorkoutPlan.exists?(runna.id)).to be(true)
    expect(WorkoutPlan.kind_supplemental_full.pluck(:suggested_wday)).to contain_exactly(1, 4)
    expect(WorkoutPlanExercise.pluck(:name)).to include("Dumbbell Romanian deadlift", "Dumbbell hip thrust", "Banded kickback")
  end

  it "keeps past sessions and notes which old plan they followed" do
    old = WorkoutPlan.create!(slug: "core-quick", name: "Core finisher",
      location: :home, plan_kind: :supplemental_quick)
    log = DailyLog.for_date(Date.new(2026, 9, 1))
    session = log.strength_sessions.create!(workout_plan: old, location: :home, notes: "Felt good")
    session.strength_exercise_logs.create!(name: "Dead bug", position: 0)

    described_class.install!

    session.reload
    expect(session.workout_plan_id).to be_nil
    expect(session.notes).to eq("Plan: Core finisher\nFelt good")
    expect(session.strength_exercise_logs.pluck(:name)).to eq([ "Dead bug" ])
  end

  it "is safe to run twice" do
    described_class.install!
    described_class.install!

    expect(WorkoutPlan.where(slug: described_class::PLANS.map { |p| p[:slug] }).count).to eq(4)
    expect(WorkoutPlanExercise.count).to eq(described_class::PLANS.sum { |p| p[:exercises].size })
  end
end
