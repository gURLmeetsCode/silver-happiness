# frozen_string_literal: true

# Shared structure: workout plans + default goals (no personal history).

Goal.find_or_create_by!(id: 1) do |g|
  g.assign_attributes(Goal.defaults)
end

def seed_plan(slug, attrs, exercises)
  plan = WorkoutPlan.find_or_create_by!(slug: slug) do |p|
    p.assign_attributes(attrs)
  end
  plan.update!(attrs)
  plan.workout_plan_exercises.destroy_all
  exercises.each_with_index do |ex, i|
    plan.workout_plan_exercises.create!(ex.merge(position: i))
  end
  plan
end

# --- Runna reference (log weights after the app session — not daily suggestions) ---

seed_plan "wednesday-home", {
  name: "Wednesday home strength (Runna)",
  location: :home,
  plan_kind: :runna_reference,
  scheduled_wday: 3,
  duration_hint: "Per Runna",
  body_targets: "Legs, Glutes, Back, Chest, Core",
  description: "Your Runna Wednesday strength session. Log Garmin calories, difficulty, and notes here after you finish in the app."
}, []

seed_plan "saturday-gym", {
  name: "Saturday gym full body (Runna)",
  location: :gym,
  plan_kind: :runna_reference,
  scheduled_wday: 6,
  duration_hint: "Per Runna + gym",
  body_targets: "Legs, Glutes, Back, Chest, Shoulders, Core",
  description: "Your Runna Saturday strength + gym day. Log Garmin calories, difficulty, and notes here after the session."
}, []

seed_plan "runna-strength", {
  name: "Runna app strength (generic)",
  location: :runna_app,
  plan_kind: :runna_reference,
  scheduled_wday: nil,
  duration_hint: "Per app",
  body_targets: "Full body",
  description: "When the Runna session doesn’t match Wed/Sat — log Garmin calories, difficulty, and notes here after."
}, []

# --- Home supplemental (dumbbells + bands, back of body) — see home_strength_plans.rb ---

require_relative "home_strength_plans"
HomeStrengthPlans.install!
