class DailyLog < ApplicationRecord
  has_many :meal_entries, -> { order(:position, :created_at) }, dependent: :destroy
  has_many :progress_photos, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :strength_sessions, dependent: :destroy

  validates :logged_on, presence: true, uniqueness: true

  after_save :sync_run_walk_workouts!

  scope :recent, -> { order(logged_on: :desc) }
  scope :for_week_of, ->(date) { where(logged_on: date.beginning_of_week..date.end_of_week).order(:logged_on) }

  def self.for_date(date)
    find_or_create_by!(logged_on: date)
  end

  def self.today
    for_date(Date.current)
  end

  def total_calories
    meal_entries.sum(:calories)
  end

  def total_protein
    meal_entries.sum(:protein_g)
  end

  def total_carbs
    meal_entries.sum(:carbs_g)
  end

  def total_fat
    meal_entries.sum(:fat_g)
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
    return 0 if workouts.activity_type_run.exists?

    run_calories.to_i
  end

  def legacy_walk_calories
    return 0 if workouts.activity_type_walk.exists?

    walk_calories.to_i
  end

  def training_day?
    run_km.present? || run_calories.to_i.positive? ||
      strength_sessions.exists? ||
      training_notes.to_s.match?(/strength|gym|lift/i)
  end

  def calorie_target
    Goal.current.calorie_target_for(self)
  end

  def target_suggestions
    DailyTargetSuggestions.new(self)
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
    parts << "Period" if on_period?
    parts << "#{water_ml} ml water" if water_ml.positive?
    parts << sleep_summary if sleep_summary.present?
    parts << feeling_check_in.truncate(40) if feeling_check_in.present?
    parts.compact_blank.join(" · ")
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

  # Adds the meals from another day that aren't already here. Copying must never
  # cost you something you already logged, so anything present is left alone and
  # the count of newly added meals is returned.
  def copy_meals_from!(other_log)
    existing = meal_entries.pluck(:meal_type, :name).to_set

    transaction do
      other_log.meal_entries.count do |entry|
        next false if existing.include?([ entry.meal_type, entry.name ])

        meal_entries.create!(
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
          water_logged_ml: 0
        )
        true
      end
    end
  end

  private

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
