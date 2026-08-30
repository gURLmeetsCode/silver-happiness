class MetricsController < ApplicationController
  def show
    @goal = Goal.current
    @today = DailyLog.today
    @week = WeeklySummary.new
    @target_suggestions = DailyTargetSuggestions.new(@today)
    @cycle = WeightCycleInsight.call(goal: @goal)
    @weight_data = @cycle.weight_series
    @weight_period_data = @cycle.period_weight_series
    @weight_target_line = @cycle.target_series
    @pregnancy_guide = @goal.gestational_weight_guidance if @goal.life_stage_pregnancy?
  end
end
