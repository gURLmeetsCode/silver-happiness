class WorkoutPlansController < ApplicationController
  def index
    @workout_plans = WorkoutPlan.includes(:workout_plan_exercises).ordered
    @supplemental_plans = @workout_plans.supplemental
    @runna_plans = @workout_plans.kind_runna_reference
    @suggested = WorkoutPlan.suggested_for
    @suggestion_context = WorkoutPlan.suggestion_context
    @today = DailyLog.today
  end

  def show
    @workout_plan = WorkoutPlan.includes(:workout_plan_exercises).find(params[:id])
    @today = DailyLog.today
  end
end
