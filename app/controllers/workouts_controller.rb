class WorkoutsController < ApplicationController
  before_action :set_daily_log

  def create
    @workout = @daily_log.workouts.build(workout_params)

    if @workout.save
      redirect_to @daily_log, notice: "Workout added."
    else
      redirect_to @daily_log, alert: @workout.errors.full_messages.to_sentence
    end
  end

  def destroy
    workout = @daily_log.workouts.find(params[:id])
    workout.destroy
    redirect_to @daily_log, notice: "Workout removed."
  end

  private

  def set_daily_log
    @daily_log = DailyLog.find(params[:daily_log_id])
  end

  def workout_params
    params.require(:workout).permit(:activity_type, :distance_km, :calories_burned, :notes)
  end
end
