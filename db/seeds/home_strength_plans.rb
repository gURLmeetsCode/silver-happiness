# frozen_string_literal: true

# Home supplemental strength: 2 × 7 kg dumbbells + resistance bands, focused on the
# back of the body (glutes, hamstrings, lower back). Shared by db/seeds/structure.rb
# and the migration that swapped these in on production.
module HomeStrengthPlans
  RETIRED_SLUGS = %w[core-quick glute-core-quick monday-home-toning thursday-home-toning].freeze

  PLANS = [
    {
      slug: "glute-activation-band",
      attrs: {
        name: "Glute activation (band)",
        location: :home,
        plan_kind: :supplemental_quick,
        suggested_wday: nil,
        duration_hint: "10 min",
        body_targets: "Glutes, Hips",
        description: "Band-only wake-up for the glutes. Good before a run or on a tired day — slow reps, squeeze at the top."
      },
      exercises: [
        { name: "Banded glute bridge", sets_prescription: "2 sets", reps_prescription: "20 reps", equipment_hint: "Band above knees, 2 sec squeeze", body_target: "Glutes" },
        { name: "Banded clamshell", sets_prescription: "2 sets", reps_prescription: "15/side", equipment_hint: "Band above knees", body_target: "Glutes, Hips" },
        { name: "Banded kickback", sets_prescription: "2 sets", reps_prescription: "12/side", equipment_hint: "Band around ankles, on all fours", body_target: "Glutes" },
        { name: "Banded lateral walk", sets_prescription: "2 sets", reps_prescription: "10 steps/side", equipment_hint: "Band above knees, stay low", body_target: "Glutes, Hips" }
      ]
    },
    {
      slug: "lower-back-care",
      attrs: {
        name: "Lower back strength",
        location: :home,
        plan_kind: :supplemental_quick,
        suggested_wday: nil,
        duration_hint: "8 min",
        body_targets: "Lower back, Glutes, Core",
        description: "Short, controlled work for the muscles along the spine plus the glutes that support them. No weights needed."
      },
      exercises: [
        { name: "Bird dog", sets_prescription: "2 sets", reps_prescription: "8/side", equipment_hint: "3 sec hold, hips level", body_target: "Lower back, Core" },
        { name: "Superman hold", sets_prescription: "2 sets", reps_prescription: "10 × 3 sec", equipment_hint: "Bodyweight, lift chest and legs", body_target: "Lower back, Glutes" },
        { name: "Glute bridge march", sets_prescription: "2 sets", reps_prescription: "10/side", equipment_hint: "Keep hips high", body_target: "Glutes, Hamstrings" },
        { name: "Dead bug", sets_prescription: "2 sets", reps_prescription: "8/side", equipment_hint: "Lower back pressed down", body_target: "Core" }
      ]
    },
    {
      slug: "glutes-hamstrings-home",
      attrs: {
        name: "Glutes & hamstrings",
        location: :home,
        plan_kind: :supplemental_full,
        suggested_wday: 1,
        duration_hint: "30 min",
        body_targets: "Glutes, Hamstrings, Lower back",
        description: "Back-of-body session with 2 × 7 kg dumbbells and a band. 7 kg gets easy on hinges — use a 3 sec lowering and pause at the bottom."
      },
      exercises: [
        { name: "Dumbbell Romanian deadlift", sets_prescription: "3 sets", reps_prescription: "12 reps", equipment_hint: "2 × 7 kg, 3 sec down", body_target: "Hamstrings, Glutes, Lower back" },
        { name: "Single-leg Romanian deadlift", sets_prescription: "3 sets", reps_prescription: "8/side", equipment_hint: "1 × 7 kg, opposite hand", body_target: "Hamstrings, Glutes" },
        { name: "Banded glute bridge", sets_prescription: "3 sets", reps_prescription: "15 reps", equipment_hint: "Band above knees + 7 kg on hips", body_target: "Glutes" },
        { name: "Banded kickback", sets_prescription: "3 sets", reps_prescription: "15/side", equipment_hint: "Band around ankles", body_target: "Glutes" },
        { name: "Banded lateral walk", sets_prescription: "2 sets", reps_prescription: "12 steps/side", equipment_hint: "Band above knees", body_target: "Glutes, Hips" },
        { name: "Bird dog", sets_prescription: "3 sets", reps_prescription: "8/side", equipment_hint: "3 sec hold", body_target: "Lower back, Core" }
      ]
    },
    {
      slug: "glutes-lower-back-home",
      attrs: {
        name: "Glutes & lower back",
        location: :home,
        plan_kind: :supplemental_full,
        suggested_wday: 4,
        duration_hint: "30 min",
        body_targets: "Glutes, Lower back, Hamstrings",
        description: "Hip thrusts, sumo hinges and band good mornings. Shoulders on the sofa for thrusts; stack both dumbbells on your hips."
      },
      exercises: [
        { name: "Dumbbell hip thrust", sets_prescription: "4 sets", reps_prescription: "15 reps", equipment_hint: "2 × 7 kg on hips, 2 sec squeeze", body_target: "Glutes" },
        { name: "Dumbbell sumo deadlift", sets_prescription: "3 sets", reps_prescription: "12 reps", equipment_hint: "Both dumbbells, wide stance", body_target: "Glutes, Hamstrings, Lower back" },
        { name: "Banded good morning", sets_prescription: "3 sets", reps_prescription: "15 reps", equipment_hint: "Stand on band, loop behind neck", body_target: "Hamstrings, Lower back" },
        { name: "Reverse lunge, forward lean", sets_prescription: "3 sets", reps_prescription: "10/side", equipment_hint: "2 × 7 kg, chest over front knee", body_target: "Glutes" },
        { name: "Superman hold", sets_prescription: "3 sets", reps_prescription: "10 × 3 sec", equipment_hint: "Bodyweight", body_target: "Lower back, Glutes" },
        { name: "Banded clamshell", sets_prescription: "2 sets", reps_prescription: "15/side", equipment_hint: "Band above knees", body_target: "Glutes, Hips" }
      ]
    }
  ].freeze

  module_function

  def install!
    retire_old_plans!
    PLANS.each do |plan_def|
      plan = WorkoutPlan.find_or_initialize_by(slug: plan_def[:slug])
      plan.update!(plan_def[:attrs])
      plan.workout_plan_exercises.delete_all
      plan_def[:exercises].each_with_index do |ex, i|
        plan.workout_plan_exercises.create!(ex.merge(position: i))
      end
    end
  end

  # Past sessions keep their logged exercises; the old plan name moves into notes
  # so history still says what was done.
  def retire_old_plans!
    WorkoutPlan.where(slug: RETIRED_SLUGS).find_each do |plan|
      StrengthSession.where(workout_plan_id: plan.id).find_each do |session|
        notes = [ "Plan: #{plan.name}", session.notes.presence ].compact.join("\n")
        session.update_columns(workout_plan_id: nil, notes: notes)
      end
      plan.workout_plan_exercises.delete_all
      plan.delete
    end
  end
end
