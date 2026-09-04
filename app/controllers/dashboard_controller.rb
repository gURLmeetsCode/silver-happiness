class DashboardController < ApplicationController
  # Home is deliberately small: a greeting, the two things worth logging the
  # moment you wake up (weight and sleep), and shortcuts to everything else.
  def show
    @goal = Goal.current
    @today = DailyLog.today
    @suggested_strength = WorkoutPlan.suggested_for
    @daily_inspo, @daily_inspo_alt = OutfitPhoto.daily_inspo_pair
    nudges = CutHabitSuggestions.call(goal: @goal, today: @today)
    @cut_suggestions = nudges.visible
    @cut_dismissed = nudges.just_dismissed
    slugs = @cut_suggestions.map(&:recipe_slug).compact
    @nudge_recipes = Recipe.visible.where(slug: slugs).index_by(&:slug)
    @protein_suggestions = ProteinGapSuggestions.call(daily_log: @today, goal: @goal, limit: 2)
  end
end
