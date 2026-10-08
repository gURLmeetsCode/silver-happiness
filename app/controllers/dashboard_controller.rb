class DashboardController < ApplicationController
  # Home is deliberately small: a greeting, the two things worth logging the
  # moment you wake up (weight and sleep), and shortcuts to everything else.
  def show
    @goal = Goal.current
    @today = DailyLog.today
    @suggested_strength = WorkoutPlan.suggested_for
    @daily_inspo, @daily_inspo_alt = OutfitPhoto.daily_inspo_pair
  end
end
