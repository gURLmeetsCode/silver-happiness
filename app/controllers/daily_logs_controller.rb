class DailyLogsController < ApplicationController
  before_action :set_daily_log, only: [ :show, :edit, :update, :copy_meals, :add_water, :set_water ]
  before_action :load_strength_context, only: [ :show, :edit, :update ]
  before_action :load_show_page, only: [ :show, :update ]

  def index
    today = Date.current
    @week_start = today.beginning_of_week
    @week_end = today.end_of_week
    @this_week_logs = DailyLog.where(logged_on: @week_start..@week_end).recent

    @focus_month = parse_month(params[:month]) || today.beginning_of_month
    month_scope = DailyLog.for_month(@focus_month).recent
    if @focus_month == today.beginning_of_month
      month_scope = month_scope.where.not(logged_on: @week_start..@week_end)
    end
    @month_logs = month_scope

    earliest = DailyLog.minimum(:logged_on)&.beginning_of_month
    @prev_month = (@focus_month - 1.month if earliest && @focus_month > earliest)
    @next_month = (@focus_month + 1.month if @focus_month < today.beginning_of_month)
  end

  def show
  end

  def edit
  end

  def update
    if @daily_log.update(daily_log_params)
      redirect_to safe_return_to(default: @daily_log), notice: "Check-in saved."
    else
      flash.now[:alert] = @daily_log.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def today
    redirect_to daily_log_path(DailyLog.today)
  end

  def copy_meals
    source = DailyLog.find(params[:source_id])
    added = @daily_log.copy_meals_from!(source)
    from = source.logged_on.strftime("%b %-d")

    notice = if added.zero?
      "Nothing new to copy — every meal from #{from} is already logged."
    else
      "Added #{added} #{'meal'.pluralize(added)} from #{from}. Your existing meals were kept."
    end

    redirect_to @daily_log, notice: notice
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

  def load_strength_context
    @runna_strength_today = WorkoutPlan.runna_for(@daily_log.logged_on)
  end

  def load_show_page
    @goal = Goal.current
    @meal_templates = MealTemplate.includes(:recipe).order(:meal_type, :name)
    @products = Product.order(:name)
    @quick_beverages = Product.quick_log_beverages
    @recent_meals = RecentMealShortcuts.call(as_of: @daily_log.logged_on)
    @custom_meal = MealEntry.new
    @workout = Workout.new
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
      :training_notes, :notes, :energy_notes,
      :on_period, :compulsive_eating_day, :water_ml, :bed_time, :wake_time, :sleep_quality, :feeling_check_in,
      :hard_day_trigger, :hard_day_what_was_available, :hard_day_next_time
    )
  end

  def parse_month(value)
    return nil if value.blank?

    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError, TypeError
    nil
  end
end
