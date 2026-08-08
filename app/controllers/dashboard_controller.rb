class DashboardController < ApplicationController
  def show
    @goal = Goal.current
    @today = DailyLog.today
    @week = WeeklySummary.new
    @meal_templates = MealTemplate.includes(:meal_template_items).order(:meal_type, :name)
    @weight_data = DailyLog.where.not(weight_kg: nil).order(:logged_on).last(30).map { |l| [ l.logged_on.strftime("%b %-d"), l.weight_kg.to_f ] }
    @weight_target_line = @weight_data.map { |date, _| [ date, @goal.target_weight_kg.to_f ] }
    @confidence_photos = OutfitPhoto.where(category: [ :feeling_cute, :reality_check ]).recent.limit(6)
    @target_suggestions = DailyTargetSuggestions.new(@today)
    @suggested_strength = WorkoutPlan.suggested_for
    @suggestion_context = WorkoutPlan.suggestion_context
  end
end
