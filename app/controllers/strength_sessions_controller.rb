class StrengthSessionsController < ApplicationController
  before_action :set_daily_log
  before_action :set_strength_session, only: [ :show, :edit, :update, :destroy ]

  def new
    if params[:workout_plan_id].present?
      plan = WorkoutPlan.find(params[:workout_plan_id])
      @strength_session = plan.build_session_for(@daily_log, location: params[:location].presence || plan.location)
    else
      @strength_session = @daily_log.strength_sessions.build(location: :home)
      @strength_session.strength_exercise_logs.build
    end
  end

  def create
    plan_id = strength_session_params[:workout_plan_id].presence
    if plan_id.present?
      existing = @daily_log.strength_sessions.find_by(workout_plan_id: plan_id)
      if existing
        redirect_to daily_log_strength_session_path(@daily_log, existing),
          notice: "That strength plan is already logged today."
        return
      end
    end

    @strength_session = @daily_log.strength_sessions.build(strength_session_params)

    if @strength_session.save
      redirect_to daily_log_strength_session_path(@daily_log, @strength_session), notice: "Strength session logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @strength_session.update(strength_session_params)
      redirect_to daily_log_strength_session_path(@daily_log, @strength_session), notice: "Session updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @strength_session.destroy
    redirect_to @daily_log, notice: "Strength session removed."
  end

  private

  def set_daily_log
    @daily_log = DailyLog.find(params[:daily_log_id])
  end

  def set_strength_session
    @strength_session = @daily_log.strength_sessions.find(params[:id])
  end

  def strength_session_params
    params.require(:strength_session).permit(
      :workout_plan_id, :location, :perceived_difficulty, :notes, :duration_min, :calories_burned,
      strength_exercise_logs_attributes: [
        :id, :name, :equipment, :weight_kg, :sets, :reps, :notes, :position, :_destroy
      ]
    )
  end
end
