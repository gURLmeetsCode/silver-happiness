class DailyLog < ApplicationRecord
  has_many :meal_entries, -> { order(:position, :created_at) }, dependent: :destroy
  has_many :progress_photos, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :strength_sessions, dependent: :destroy
  has_many :urge_check_ins, dependent: :destroy

  validates :logged_on, presence: true, uniqueness: true

  after_save :sync_run_walk_workouts!

  scope :recent, -> { order(logged_on: :desc) }
  scope :for_week_of, ->(date) { where(logged_on: date.beginning_of_week..date.end_of_week).order(:logged_on) }
  scope :for_month, ->(date) {
    month = date.to_date.beginning_of_month
    where(logged_on: month..month.end_of_month)
  }
  scope :with_journal_content, -> {
    left_joins(:urge_check_ins).where(
      "COALESCE(TRIM(daily_logs.notes), '') != '' OR " \
      "COALESCE(TRIM(daily_logs.feeling_check_in), '') != '' OR " \
      "daily_logs.on_period = ? OR daily_logs.compulsive_eating_day = ? OR " \
      "COALESCE(TRIM(daily_logs.hard_day_trigger), '') != '' OR " \
      "COALESCE(TRIM(daily_logs.hard_day_what_was_available), '') != '' OR " \
      "COALESCE(TRIM(daily_logs.hard_day_next_time), '') != '' OR " \
      "urge_check_ins.id IS NOT NULL",
      true, true
    ).distinct
  }

  def self.for_date(date)
    find_or_create_by!(logged_on: date)
  rescue ActiveRecord::RecordNotUnique
    find_by!(logged_on: date)
  end

  def self.today
    for_date(Date.current)
  end

  def total_calories
    loaded_meal_sum(:calories) { meal_entries.sum(:calories) }
  end

  def total_protein
    loaded_meal_sum(:protein_g) { meal_entries.sum(:protein_g) }
  end

  def total_carbs
    loaded_meal_sum(:carbs_g) { meal_entries.sum(:carbs_g) }
  end

  def total_fat
    loaded_meal_sum(:fat_g) { meal_entries.sum(:fat_g) }
  end

  def calories_burned
    calories_burned_breakdown.sum { |part| part[:kcal].to_i }
  end

  def calories_burned_breakdown
    parts = workouts.filter_map do |workout|
      next unless workout.calories_burned.to_i.positive?

      { label: workout.activity_type.humanize, kcal: workout.calories_burned }
    end

    strength_sessions.each do |session|
      next unless session.calories_burned.to_i.positive?

      parts << { label: session.title, kcal: session.calories_burned }
    end

    parts << { label: "Run", kcal: legacy_run_calories } if legacy_run_calories.positive?
    parts << { label: "Walk", kcal: legacy_walk_calories } if legacy_walk_calories.positive?

    parts
  end

  def legacy_run_calories
    return 0 if workouts_include_type?(:run)

    run_calories.to_i
  end

  def legacy_walk_calories
    return 0 if workouts_include_type?(:walk)

    walk_calories.to_i
  end

  def training_day?
    run_km.present? || run_calories.to_i.positive? ||
      strength_logged? ||
      training_notes.to_s.match?(/strength|gym|lift/i)
  end

  def calorie_target
    Goal.current.calorie_target_for(self)
  end

  def net_calories
    total_calories - calories_burned
  end

  def training_summary
    parts = workouts.map(&:summary)
    strength_sessions.each do |session|
      line = session.title
      line += " (#{session.calories_burned} kcal)" if session.calories_burned.to_i.positive?
      line += " · #{session.duration_min} min" if session.duration_min.present?
      parts << line
    end
    parts << "Run #{run_km}km (#{run_calories} kcal)" if run_km.present? && workouts.none?
    parts << "Walk #{walk_km}km (#{walk_calories} kcal)" if walk_km.present? && workouts.none?
    parts << training_notes if training_notes.present?
    parts.compact_blank.join(" · ")
  end

  FEELING_TAGS = [
    "Bloated", "Light", "Tired", "Strong", "Crampy", "Hungry",
    "Puffy", "Good energy", "Sore", "Anxious", "Heavy", "Calm"
  ].freeze

  SLEEP_QUALITY_OPTIONS = [
    [ "1 — Restless, barely slept", 1 ],
    [ "2 — Very broken sleep", 2 ],
    [ "3 — Poor", 3 ],
    [ "4 — Below average", 4 ],
    [ "5 — OK", 5 ],
    [ "6 — Decent", 6 ],
    [ "7 — Good", 7 ],
    [ "8 — Very good", 8 ],
    [ "9 — Great", 9 ],
    [ "10 — Best sleep in ages", 10 ]
  ].freeze

  def water_glasses
    return 0 if water_ml.zero?

    (water_ml / 250.0).round(1)
  end

  def sleep_duration_hours
    return nil unless bed_time && wake_time

    bed = bed_time
    wake = wake_time
    # Assume wake is same day or next morning if wake < bed
    wake += 1.day if wake <= bed
    ((wake - bed) / 1.hour).round(1)
  end

  def sleep_summary
    return nil unless bed_time && wake_time

    parts = [ sleep_window_label ]
    parts << "#{sleep_duration_hours}h" if sleep_duration_hours
    parts << sleep_quality_label if sleep_quality.present?
    parts.join(" · ")
  end

  def sleep_window_label
    return nil unless bed_time && wake_time

    bed_day = logged_on - 1.day
    "#{bed_day.strftime('%a')} #{format_time(bed_time)} → #{logged_on.strftime('%a')} #{format_time(wake_time)}"
  end

  def sleep_quality_label
    return nil unless sleep_quality.present?

    DailyLog::SLEEP_QUALITY_OPTIONS.assoc(sleep_quality)&.first || "Quality #{sleep_quality}/10"
  end

  def wellness_summary
    parts = []
    parts << "Hard eating day" if compulsive_eating_day?
    parts << "Period" if on_period?
    parts << "#{water_ml} ml water" if water_ml.positive?
    parts << sleep_summary if sleep_summary.present?
    parts << feeling_check_in.truncate(40) if feeling_check_in.present?
    if urge_check_ins.any?
      paused = urge_check_ins.count(&:paused?)
      parts << "#{urge_check_ins.size} urge#{"s" if urge_check_ins.size != 1} (#{paused} paused)"
    end
    parts.compact_blank.join(" · ")
  end

  def hard_day_debrief?
    hard_day_trigger.present? || hard_day_what_was_available.present? || hard_day_next_time.present?
  end

  # Rough nudge for the urge flow — not medical advice, just today's logged protein.
  def protein_status_suggestion
    goal = Goal.current
    protein = total_protein
    return "unsure" if meal_entries.none?
    return "yes" if protein >= goal.protein_min_g
    return "no" if protein < (goal.protein_min_g * 0.6)

    "unsure"
  end

  def energy_estimate
    Goal.current.energy_estimate(weight_kg: weight_kg)
  end

  def add_water!(amount_ml = 250)
    update!(water_ml: water_ml + amount_ml)
  end

  def sync_run_walk_workouts!
    sync_activity_workout!(:run, run_km, run_calories)
    sync_activity_workout!(:walk, walk_km, walk_calories)
  end

  def meals_with_water_logged
    meal_entries.count(&:water_logged?)
  end

  def meals_pending_water
    meal_entries.reject(&:water_logged?)
  end

  def meal_water_progress_label
    total = meal_entries.size
    return nil if total.zero?

    logged = meals_with_water_logged
    "#{logged}/#{total} meals with water"
  end

  # Adds selected meals from another day (defaults to all). Copies ingredients
  # too, so built meals stay editable. Never overwrites meals already logged.
  def copy_meals_from!(other_log, meal_entry_ids: nil)
    entries = other_log.meal_entries.includes(:items).order(:position, :id)
    if meal_entry_ids.present?
      ids = Array(meal_entry_ids).map(&:to_i)
      entries = entries.select { |entry| ids.include?(entry.id) }
    end

    existing = meal_entries.pluck(:meal_type, :name).to_set

    transaction do
      entries.count do |entry|
        next false if existing.include?([ entry.meal_type, entry.name ])

        copy = meal_entries.create!(
          meal_type: entry.meal_type,
          name: entry.name,
          calories: entry.calories,
          protein_g: entry.protein_g,
          carbs_g: entry.carbs_g,
          fat_g: entry.fat_g,
          meal_template: entry.meal_template,
          notes: entry.notes,
          position: entry.position,
          water_suggestion_ml: entry.water_suggestion_ml,
          water_logged_ml: 0,
          ingredient_overrides: entry.ingredient_overrides
        )
        if entry.items.any?
          copy.record_items!(entry.items.map { |item| { product_id: item.product_id, grams: item.grams } })
          copy.save!
        end
        true
      end
    end
  end

  private

  def loaded_meal_sum(attribute)
    if meal_entries.loaded?
      meal_entries.sum { |entry| entry.public_send(attribute).to_f }
    else
      yield
    end
  end

  def workouts_include_type?(type)
    if workouts.loaded?
      workouts.any? { |workout| workout.public_send("activity_type_#{type}?") }
    else
      workouts.public_send("activity_type_#{type}").exists?
    end
  end

  def strength_logged?
    if strength_sessions.loaded?
      strength_sessions.any?
    else
      strength_sessions.exists?
    end
  end

  def sync_activity_workout!(type, km, kcal)
    existing = workouts.where(activity_type: type).order(:id).to_a

    if kcal.to_i.positive? || km.present?
      # A day has at most one run and one walk; extras would double-count in
      # calories_burned_breakdown.
      workout = existing.shift || workouts.build(activity_type: type)
      existing.each(&:destroy)

      workout.calories_burned = kcal.to_i if kcal.to_i.positive?
      workout.calories_burned = 0 if workout.calories_burned.nil?
      workout.distance_km = km if km.present?
      # Clear stale distance when the field was emptied but calories remain.
      workout.distance_km = nil if km.blank? && kcal.to_i.positive?
      workout.save!
    else
      existing.each(&:destroy)
    end

    workouts.reset
  end

  def format_time(time)
    time.strftime("%H:%M")
  end
end
