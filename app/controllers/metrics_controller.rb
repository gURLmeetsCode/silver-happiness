class MetricsController < ApplicationController
  before_action :load_metrics

  def show
  end

  def export
    pdf = MetricsReportPdf.render(
      goal: @goal,
      today: @today,
      week: @week,
      trends: @trends,
      cycle: @cycle
    )
    send_data pdf,
      filename: "silver-happiness-metrics-#{Date.current.iso8601}.pdf",
      type: "application/pdf",
      disposition: "attachment"
  end

  private

  def load_metrics
    @goal = Goal.current
    @today = DailyLog.today
    @week = WeeklySummary.new
    @trends = MetricsTrends.call(goal: @goal)
    @cycle = WeightCycleInsight.call(goal: @goal)
    @weight_data = @cycle.weight_series
    @weight_period_data = @cycle.period_weight_series
    @weight_target_line = @cycle.target_series
    @pregnancy_guide = @goal.gestational_weight_guidance if @goal.life_stage_pregnancy?
  end
end
