class DailyLog < ApplicationRecord
  enum :portions_on_plan, { yes: 0, mostly: 1, no: 2 }, prefix: :portions

  has_many :meal_entries, -> { order(:position, :created_at) }, dependent: :destroy
  has_many :progress_photos, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :strength_sessions, dependent: :destroy

  validates :logged_on, presence: true, uniqueness: true

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
    from_workouts = workouts.sum(:calories_burned)
    return from_workouts if from_workouts.positive?

    (run_calories || 0) + (walk_calories || 0)
  end

  def training_day?
    run_km.present? || run_calories.to_i.positive? || training_notes.to_s.match?(/strength|gym|lift/i)
  end

  def calorie_target
    Goal.current.calorie_target_for(self)
  end

  def net_calories
    total_calories - calories_burned
  end

  def training_summary
    parts = workouts.map(&:summary)
    parts << "Run #{run_km}km (#{run_calories} kcal)" if run_km.present? && workouts.none?
    parts << "Walk #{walk_km}km (#{walk_calories} kcal)" if walk_km.present? && workouts.none?
    parts << training_notes if training_notes.present?
    parts.compact_blank.join(" · ")
  end

  FEELING_TAGS = [
    "Bloated", "Light", "Tired", "Strong", "Crampy", "Hungry",
    "Puffy", "Good energy", "Sore", "Anxious", "Heavy", "Calm"
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
    parts = []
    parts << "#{format_time(bed_time)} → #{format_time(wake_time)}" if bed_time && wake_time
    parts << "#{sleep_duration_hours}h" if sleep_duration_hours
    parts << "quality #{sleep_quality}/10" if sleep_quality.present?
    parts.join(" · ")
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

  private

  def format_time(time)
    time.strftime("%H:%M")
  end

  def copy_meals_from!(other_log)
    transaction do
      meal_entries.destroy_all
      other_log.meal_entries.each do |entry|
        meal_entries.create!(
          meal_type: entry.meal_type,
          name: entry.name,
          calories: entry.calories,
          protein_g: entry.protein_g,
          meal_template: entry.meal_template,
          notes: entry.notes,
          position: entry.position,
          water_suggestion_ml: entry.water_suggestion_ml,
          water_logged_ml: 0
        )
      end
    end
  end
end
