# frozen_string_literal: true

require_relative "../seeds/home_strength_plans"

class SwapInHomePosteriorChainPlans < ActiveRecord::Migration[8.0]
  def up
    WorkoutPlan.reset_column_information
    WorkoutPlanExercise.reset_column_information
    StrengthSession.reset_column_information

    HomeStrengthPlans.install!
  end

  def down
    # Old plans are gone; re-running db:seed from an older commit restores them.
  end
end
