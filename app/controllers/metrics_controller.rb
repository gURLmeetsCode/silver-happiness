class MetricsController < ApplicationController
  def show
    @goal = Goal.current
    @today = DailyLog.today
    @week = WeeklySummary.new
    @target_suggestions = DailyTargetSuggestions.new(@today)
    @weight_data = DailyLog.where.not(weight_kg: nil)
      .order(:logged_on).last(30)
      .map { |log| [ log.logged_on.strftime("%b %-d"), log.weight_kg.to_f ] }
    @weight_target_line = @weight_data.map { |date, _| [ date, @goal.target_weight_kg.to_f ] }
  end
end
