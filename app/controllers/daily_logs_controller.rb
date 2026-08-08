class DailyLogsController < ApplicationController
  before_action :set_daily_log, only: [ :show, :edit, :update, :copy_meals, :add_water, :set_water ]
  before_action :load_show_page, only: [ :show, :update ]

  def index
    @daily_logs = DailyLog.recent.limit(60)
  end

  def show
  end

  def edit
  end

  def update
    if @daily_log.update(daily_log_params)
      redirect_to @daily_log, notice: "Check-in saved."
    else
      flash.now[:alert] = @daily_log.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def today
    redirect_to daily_log_path(DailyLog.today)
  end

  def copy_meals
    source = DailyLog.find(params[:source_id])
    @daily_log.copy_meals_from!(source)
    redirect_to @daily_log, notice: "Meals copied from #{source.logged_on.strftime('%b %-d')}."
  end

  def add_water
    amount = params[:amount_ml].to_i
    amount = 250 if amount <= 0
    @daily_log.add_water!(amount)
    redirect_to @daily_log, notice: "Added #{amount} ml water (#{@daily_log.water_ml} ml total)."
  end

  def set_water
    amount = [ params[:amount_ml].to_i, 0 ].max
    @daily_log.update!(water_ml: amount)
    redirect_to @daily_log, notice: "Water set to #{amount} ml (#{@daily_log.water_glasses} glasses)."
  end

  private

  def set_daily_log
    @daily_log = params[:id] == "today" ? DailyLog.today : DailyLog.find(params[:id])
  end

  def load_show_page
    @goal = Goal.current
    @meal_templates = MealTemplate.order(:meal_type, :name)
    @products = Product.order(:name)
    @custom_meal = MealEntry.new
    @workout = Workout.new
    @runna_strength_today = WorkoutPlan.runna_for(@daily_log.logged_on)
    @target_suggestions = DailyTargetSuggestions.new(@daily_log)
    @suggested_strength = WorkoutPlan.suggested_for(@daily_log.logged_on)
    @suggestion_context = WorkoutPlan.suggestion_context(@daily_log.logged_on)
    @workout_plans = WorkoutPlan.ordered
    @supplemental_plans = @workout_plans.supplemental
    @runna_plans = @workout_plans.kind_runna_reference
  end

  def daily_log_params
    params.require(:daily_log).permit(
      :weight_kg, :weight_pre_run, :run_km, :run_calories, :walk_km, :walk_calories,
      :training_notes, :notes, :portions_on_plan, :energy_notes,
      :on_period, :water_ml, :bed_time, :wake_time, :sleep_quality, :feeling_check_in
    )
  end
end
