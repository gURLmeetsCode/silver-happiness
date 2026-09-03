# frozen_string_literal: true

# A few concrete cut nudges from recent eating/run habits — not a calorie cop.
# Dismiss snoozes for a week; "not helpful" hides that key permanently.
class CutHabitSuggestions
  Suggestion = Data.define(:key, :title, :body, :recipe_slug)

  LOOKBACK_DAYS = 21
  MAX_VISIBLE = 3
  COMPLETE_KCAL = 900
  TREAT_NAME = /brownie|pancake|crêpe|crepe|binge|m&m|ice cream|chips/i
  WRAP_NAME = /wrap|chipotle/i
  HIGH_TREAT_KCAL = 500
  HEAVY_WRAP_KCAL = 800

  TITLES = {
    "today_over" => "Today is already over the line",
    "weekend_leak" => "Weekends are the leak",
    "dont_eat_back" => "Don't eat the run twice",
    "treat_serving" => "One piece, not the tray",
    "wrap_portion" => "A lighter lunch than the big wrap",
    "sleep_before_run" => "Sleep before the hard run",
    "water_on_run" => "Water on run mornings",
    "dinner_plate" => "Dinner that feels full, not dense",
    "lunch_volume" => "Lunch with volume",
    "breakfast_anchor" => "Start with the usual breakfast",
    "close_kitchen" => "Not much room left today",
    "maintenance_gap" => "Average intake is maintenance"
  }.freeze

  def self.call(goal:, today:, now: Time.current)
    new(goal:, today:, now:).call
  end

  def initialize(goal:, today:, now: Time.current)
    @goal = goal
    @today = today
    @now = now
    @date = today.logged_on
  end

  def call
    return Result.new(visible: [], just_dismissed: []) if @goal.life_stage_pregnancy?

    hidden = HabitSuggestionFeedback.hidden_keys(on: @date)
    visible = candidates.reject { |s| hidden.include?(s.key) }.first(MAX_VISIBLE)
    dismissed_keys = HabitSuggestionFeedback.dismissed_today_keys
    just_dismissed = dismissed_keys.filter_map do |key|
      title = catalog_title(key)
      next if title.blank?

      Suggestion.new(key:, title:, body: "", recipe_slug: nil)
    end

    Result.new(visible:, just_dismissed:)
  end

  Result = Data.define(:visible, :just_dismissed)

  private

  def catalog_title(key)
    TITLES[key]
  end

  def candidates
    [
      today_over,
      weekend_leak,
      dont_eat_back,
      treat_serving,
      wrap_portion,
      sleep_before_run,
      water_on_run,
      meal_slot,
      maintenance_gap
    ].compact
  end

  def suggestion(key, body, recipe_slug: nil)
    Suggestion.new(key:, title: TITLES.fetch(key), body:, recipe_slug:)
  end

  def logs
    @logs ||= DailyLog
      .includes(:meal_entries, :workouts)
      .where(logged_on: (@date - LOOKBACK_DAYS)..@date)
      .order(:logged_on)
      .to_a
  end

  def complete_days
    @complete_days ||= logs.select { |d| d.logged_on < @date && d.total_calories >= COMPLETE_KCAL }
  end

  def weekday_days
    complete_days.reject { |d| d.logged_on.saturday? || d.logged_on.sunday? }
  end

  def weekend_days
    complete_days.select { |d| d.logged_on.saturday? || d.logged_on.sunday? }
  end

  def avg(days)
    return nil if days.empty?

    (days.sum(&:total_calories) / days.size.to_f).round
  end

  def run_day?(log)
    log.run_km.to_f.positive? || log.run_calories.to_i.positive? ||
      log.workouts.any? { |w| w.activity_type_run? }
  end

  def typical_run_wday?(wday)
    run_wdays = complete_days.select { |d| run_day?(d) }.map { |d| d.logged_on.wday }
    return false if run_wdays.size < 2

    run_wdays.count(wday) >= 2
  end

  def run_likely_today?
    @today.training_day? || run_day?(@today) || typical_run_wday?(@date.wday)
  end

  def today_over
    eaten = @today.total_calories
    return if eaten < COMPLETE_KCAL
    return if eaten <= @today.calorie_target + 100

    over = eaten - @today.calorie_target
    suggestion(
      "today_over",
      "You're about #{over} kcal over ~#{@today.calorie_target}. Close extras — tea, fruit, or leftover veg. Don't try to 'make it a good day' with more food."
    )
  end

  def weekend_leak
    wday = avg(weekday_days)
    wend = avg(weekend_days)
    return unless wday && wend && weekend_days.size >= 2 && wend >= wday + 250

    weekendish = @date.friday? || @date.saturday? || @date.sunday?
    return unless weekendish || wend >= 2200

    target = [ wday, @goal.calories_rest_day ].min
    suggestion(
      "weekend_leak",
      "Weekdays average ~#{wday} kcal; weekends ~#{wend}. That gap is why the 7-day weight average stalled. Keep today near #{target} — one treat serving, not a second snack."
    )
  end

  def dont_eat_back
    return unless run_likely_today?

    suggestion(
      "dont_eat_back",
      "Your #{@goal.calories_training_day} kcal training target already includes the run. Extra post-run snacks are a second eat-back. Breakfast + usual lunch + a light dinner is enough."
    )
  end

  def treat_meals
    complete_days.flat_map(&:meal_entries).select { |m|
      m.calories.to_i >= HIGH_TREAT_KCAL && m.name.match?(TREAT_NAME)
    }
  end

  def treat_serving
    meals = treat_meals
    return if meals.empty?

    biggest = meals.max_by { |m| m.calories.to_i }
    suggestion(
      "treat_serving",
      "#{biggest.name} logged at #{biggest.calories} kcal — that's a tray, not a serving. Freeze extras and log one piece (~150–250 kcal) next time."
    )
  end

  def wrap_portion
    wraps = complete_days.flat_map(&:meal_entries).select { |m|
      m.calories.to_i >= HEAVY_WRAP_KCAL && m.name.match?(WRAP_NAME)
    }
    return if wraps.empty?
    return if slot_logged?(:lunch)

    suggestion(
      "wrap_portion",
      "Chipotle-style wraps have landed at #{wraps.map(&:calories).max.to_i} kcal. Power salad or Thai rice-paper wraps keep lunch filling without the spike.",
      recipe_slug: recipe_slug_for(%w[thai-vegan-wraps power-salad])
    )
  end

  def sleep_before_run
    last_night = @today.sleep_duration_hours
    last_night ||= logs.find { |d| d.logged_on == @date - 1 }&.sleep_duration_hours
    short = last_night.present? && last_night < 7
    hard_tomorrow = typical_run_wday?((@date + 1).wday)

    return unless run_likely_today? || hard_tomorrow
    return unless short || hard_tomorrow

    if short && run_likely_today?
      suggestion(
        "sleep_before_run",
        "Last night was #{last_night} h. Heavy, stop-and-start runs clustered after short sleep. Keep today easy if you can, and protect 7 h tonight."
      )
    elsif hard_tomorrow
      suggestion(
        "sleep_before_run",
        "Long or hill days felt worse after under 7 h. Aim for 7 h+ tonight if you're running tomorrow."
      )
    end
  end

  def water_on_run
    return unless run_likely_today?

    run_days = complete_days.select { |d| run_day?(d) }
    dry = run_days.count { |d| d.water_ml.to_i < 400 }
    return if run_days.size < 3 || dry < 2
    return if @today.water_ml.to_i >= 500

    suggestion(
      "water_on_run",
      "On several run days water was barely logged, and those mornings felt heavy or shaky. Bottle before you leave — start toward #{@goal.water_goal_ml} ml."
    )
  end

  def meal_slot
    remaining = @today.calorie_target - @today.total_calories
    hour = @now.hour

    if remaining < 250 && @today.total_calories.positive? && hour >= 16
      return suggestion(
        "close_kitchen",
        "Not much room left (~#{[ remaining, 0 ].max} kcal). Skip another cooked meal — cucumber, mâche, tea."
      )
    end

    if hour < 11 && !slot_logged?(:breakfast)
      slug = run_likely_today? ? "run-day-oats" : "rest-day-yogurt"
      return suggestion(
        "breakfast_anchor",
        run_likely_today? ? "Run-day oats + protein, then don't add a café extra on top." : "Usual yogurt breakfast. Hold the extras for later if you want a treat.",
        recipe_slug: recipe_slug_for([ slug ])
      )
    end

    if hour < 16 && !slot_logged?(:lunch)
      return suggestion(
        "lunch_volume",
        "Power salad or Thai wraps beat a dense wrap/pasta bowl at lunch if you want the evening to stay light.",
        recipe_slug: recipe_slug_for(%w[thai-vegan-wraps power-salad])
      )
    end

    return if slot_logged?(:dinner)

    suggestion(
      "dinner_plate",
      "Oven brochettes plate (2 skewers + big salad + ½ cup quinoa) is a full dinner without a heavy tray.",
      recipe_slug: recipe_slug_for(%w[oven-brochettes-plate])
    )
  end

  def maintenance_gap
    eaten = avg(complete_days)
    energy = @goal.energy_estimate(weight_kg: @today.weight_kg)
    return unless eaten && energy.ready?
    return if energy.tdee - eaten >= 150

    suggestion(
      "maintenance_gap",
      "Last #{complete_days.size} complete days averaged ~#{eaten} kcal vs maintenance ~#{energy.tdee}. That's why the scale's 7-day average is stuck. Weekdays are fine; shave weekends and trays, not more running."
    )
  end

  def slot_logged?(type)
    @today.meal_entries.any? { |m| m.public_send("meal_type_#{type}?") }
  end

  def recipe_slug_for(slugs)
    found = Recipe.visible.where(slug: slugs).pluck(:slug)
    slugs.find { |slug| found.include?(slug) }
  end
end
