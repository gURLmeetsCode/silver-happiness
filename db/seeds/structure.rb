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
  description: "Your Runna Wednesday strength session. Log weights and difficulty here after you finish in the app."
}, [
  { name: "Goblet squat", sets_prescription: "3 sets", reps_prescription: "12 reps", equipment_hint: "Dumbbell (7.5→10 kg)", body_target: "Legs, Glutes" },
  { name: "Single-arm row", sets_prescription: "3 sets", reps_prescription: "12 reps each side", equipment_hint: "Dumbbell", body_target: "Back, Arms" },
  { name: "Glute bridge", sets_prescription: "3 sets", reps_prescription: "15 reps", equipment_hint: "Bodyweight or band", body_target: "Glutes" },
  { name: "Push-ups", sets_prescription: "3 sets", reps_prescription: "AMRAP", equipment_hint: "Incline if needed", body_target: "Chest, Arms" },
  { name: "Dead bug", sets_prescription: "3 sets", reps_prescription: "10/side", equipment_hint: "Bodyweight", body_target: "Core" },
  { name: "Side plank", sets_prescription: "3 sets", reps_prescription: "20 sec/side", equipment_hint: "Bodyweight", body_target: "Core, Obliques" }
]

seed_plan "saturday-gym", {
  name: "Saturday gym full body (Runna)",
  location: :gym,
  plan_kind: :runna_reference,
  scheduled_wday: 6,
  duration_hint: "Per Runna + gym",
  body_targets: "Legs, Glutes, Back, Chest, Shoulders, Core",
  description: "Your Runna Saturday strength + gym day. Log what you actually did — machines, DBs, app session."
}, [
  { name: "Goblet squat or leg press", sets_prescription: "3 sets", reps_prescription: "10–12 reps", equipment_hint: "Dumbbell or leg press machine", body_target: "Legs, Glutes" },
  { name: "Romanian deadlift", sets_prescription: "3 sets", reps_prescription: "10 reps", equipment_hint: "Dumbbell or barbell", body_target: "Hamstrings, Glutes, Back" },
  { name: "Lat pulldown", sets_prescription: "3 sets", reps_prescription: "10–12 reps", equipment_hint: "Cable machine", body_target: "Back, Arms" },
  { name: "Chest press", sets_prescription: "3 sets", reps_prescription: "10 reps", equipment_hint: "Dumbbell or machine", body_target: "Chest, Arms" },
  { name: "Shoulder press", sets_prescription: "3 sets", reps_prescription: "10 reps", equipment_hint: "Dumbbells (try 10 kg → 12.5 kg)", body_target: "Shoulders, Arms" },
  { name: "Plank", sets_prescription: "3 sets", reps_prescription: "30–45 sec", equipment_hint: "Bodyweight", body_target: "Core" },
  { name: "Dead bug", sets_prescription: "3 sets", reps_prescription: "12/side", equipment_hint: "Bodyweight — lower stomach focus", body_target: "Core" }
]

seed_plan "runna-strength", {
  name: "Runna app strength (generic)",
  location: :runna_app,
  plan_kind: :runna_reference,
  scheduled_wday: nil,
  duration_hint: "Per app",
  body_targets: "Full body",
  description: "When the Runna session doesn’t match the Wed/Sat templates — log weights and difficulty here after."
}, [
  { name: "Runna session exercises", sets_prescription: "As app", reps_prescription: "As app", equipment_hint: "Per Runna (usually 7.5 kg DBs home)", body_target: "Full body" }
]

# --- Supplemental quick add-ons (suggested on run days + after Runna strength) ---

seed_plan "core-quick", {
  name: "Core finisher",
  location: :home,
  plan_kind: :supplemental_quick,
  duration_hint: "8 min",
  body_targets: "Core, Abs",
  description: "Quick add-on after a run or Runna strength day. Lower stomach focus, no extra equipment."
}, [
  { name: "Dead bug", sets_prescription: "1 round", reps_prescription: "10/side", equipment_hint: "Bodyweight", body_target: "Core, Abs" },
  { name: "Bird dog", sets_prescription: "1 round", reps_prescription: "10/side", equipment_hint: "Bodyweight", body_target: "Core, Back" },
  { name: "Hollow hold", sets_prescription: "1 round", reps_prescription: "20 sec", equipment_hint: "Bodyweight", body_target: "Core, Abs" }
]

seed_plan "glute-core-quick", {
  name: "Glute + core quick",
  location: :home,
  plan_kind: :supplemental_quick,
  duration_hint: "12 min",
  body_targets: "Glutes, Core, Obliques",
  description: "Light add-on for flat-midsection focus — glute activation plus core. Good after runs or on tired days."
}, [
  { name: "Glute bridge", sets_prescription: "2 sets", reps_prescription: "15 reps", equipment_hint: "Bodyweight, pause at top", body_target: "Glutes" },
  { name: "Clamshell", sets_prescription: "2 sets", reps_prescription: "12/side", equipment_hint: "Band optional", body_target: "Glutes, Hips" },
  { name: "Dead bug", sets_prescription: "2 sets", reps_prescription: "8/side", equipment_hint: "Slow and controlled", body_target: "Core, Abs" },
  { name: "Side plank", sets_prescription: "2 sets", reps_prescription: "20 sec/side", equipment_hint: "Knees down if needed", body_target: "Core, Obliques" }
]

# --- Supplemental full sessions (Mon / Thu — extra toning beyond Runna) ---

seed_plan "monday-home-toning", {
  name: "Monday home toning",
  location: :home,
  plan_kind: :supplemental_full,
  suggested_wday: 1,
  duration_hint: "30–35 min",
  body_targets: "Legs, Glutes, Back, Core",
  description: "Full supplemental session for Monday — no Runna run today. Legs, glutes, and core with home dumbbells."
}, [
  { name: "Goblet squat", sets_prescription: "3 sets", reps_prescription: "12 reps", equipment_hint: "Dumbbell 7.5 kg", body_target: "Legs, Glutes" },
  { name: "Romanian deadlift", sets_prescription: "3 sets", reps_prescription: "10 reps", equipment_hint: "Dumbbells", body_target: "Hamstrings, Glutes, Back" },
  { name: "Single-arm row", sets_prescription: "3 sets", reps_prescription: "12/side", equipment_hint: "Dumbbell", body_target: "Back, Arms" },
  { name: "Glute bridge march", sets_prescription: "3 sets", reps_prescription: "12/side", equipment_hint: "Bodyweight", body_target: "Glutes, Core" },
  { name: "Plank", sets_prescription: "3 sets", reps_prescription: "30 sec", equipment_hint: "Bodyweight", body_target: "Core" }
]

seed_plan "thursday-home-toning", {
  name: "Thursday home toning",
  location: :home,
  plan_kind: :supplemental_full,
  suggested_wday: 4,
  duration_hint: "30–35 min",
  body_targets: "Chest, Shoulders, Back, Legs, Core",
  description: "Full supplemental session for Thursday — upper body push/pull plus core. Fits between Runna run days."
}, [
  { name: "Push-ups", sets_prescription: "3 sets", reps_prescription: "AMRAP", equipment_hint: "Incline if needed", body_target: "Chest, Arms" },
  { name: "Dumbbell shoulder press", sets_prescription: "3 sets", reps_prescription: "10 reps", equipment_hint: "7.5 kg DBs", body_target: "Shoulders, Arms" },
  { name: "Bent-over row", sets_prescription: "3 sets", reps_prescription: "12 reps", equipment_hint: "Dumbbells", body_target: "Back, Arms" },
  { name: "Reverse lunge", sets_prescription: "3 sets", reps_prescription: "10/side", equipment_hint: "Bodyweight or goblet hold", body_target: "Legs, Glutes" },
  { name: "Dead bug", sets_prescription: "3 sets", reps_prescription: "10/side", equipment_hint: "Bodyweight", body_target: "Core, Abs" },
  { name: "Side plank", sets_prescription: "2 sets", reps_prescription: "25 sec/side", equipment_hint: "Bodyweight", body_target: "Core, Obliques" }
]
