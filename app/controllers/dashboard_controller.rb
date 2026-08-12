class DashboardController < ApplicationController
  # Home is deliberately small: a greeting, the two things worth logging the
  # moment you wake up (weight and sleep), and shortcuts to everything else.
  def show
    @goal = Goal.current
    @today = DailyLog.today
    @suggested_strength = WorkoutPlan.suggested_for
    @daily_inspo = OutfitPhoto.daily_inspo_for
    @daily_inspo_alt = OutfitPhoto.daily_inspo_alternate(@daily_inspo)
  end
end
