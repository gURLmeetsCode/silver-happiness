class WorkoutPlan < ApplicationRecord
  enum :location, { home: 0, gym: 1, runna_app: 2 }, prefix: true
  enum :plan_kind, {
    runna_reference: 0,
    supplemental_quick: 1,
    supplemental_full: 2
  }, prefix: :kind

  RUNNA_STRENGTH_WDAYS = [ 3, 6 ].freeze # Wed, Sat — handled in Runna app
  FULL_SUPPLEMENTAL_WDAYS = [ 1, 4 ].freeze # Mon, Thu
  RUN_DAYS = [ 0, 2, 5, 6 ].freeze # Sun, Tue, Fri, Sat

  has_many :workout_plan_exercises, -> { order(:position) }, dependent: :destroy
  has_many :strength_sessions, dependent: :nullify

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:plan_kind, :suggested_wday, :name) }
  scope :supplemental, -> { where(plan_kind: [ :supplemental_quick, :supplemental_full ]) }

  LOCATION_LABELS = {
    "home" => "Home",
    "gym" => "Gym",
    "runna_app" => "Runna app"
  }.freeze

  PLAN_KIND_LABELS = {
    "runna_reference" => "Runna (log only)",
    "supplemental_quick" => "Quick add-on",
    "supplemental_full" => "Full supplemental"
  }.freeze

  def location_label
    LOCATION_LABELS[location] || location.humanize
  end

  def plan_kind_label
    PLAN_KIND_LABELS[plan_kind] || plan_kind.humanize
  end

  def body_target_labels
    if body_targets.present?
      body_targets.split(/[,·\/]/).map(&:strip).reject(&:blank?)
    else
      workout_plan_exercises.filter_map { |exercise| exercise.body_target.presence }
        .flat_map { |target| target.split(/[,·\/]/) }
        .map(&:strip)
        .reject(&:blank?)
        .uniq
    end
  end

  def body_targets_summary
    body_target_labels.join(" · ")
  end

  def scheduled_day_name
    if kind_runna_reference? && scheduled_wday.present?
      "Runna · #{Date::DAYNAMES[scheduled_wday]}"
    elsif kind_supplemental_full? && suggested_wday.present?
      "Best on #{Date::DAYNAMES[suggested_wday]}"
    elsif kind_supplemental_quick?
      "Add-on anytime"
    else
      "Any day"
    end
  end

  def self.suggested_for(date = Date.current)
    if FULL_SUPPLEMENTAL_WDAYS.include?(date.wday)
      kind_supplemental_full.find_by(suggested_wday: date.wday) || kind_supplemental_full.first
    else
      quick_plans = kind_supplemental_quick.order(:slug).to_a
      return nil if quick_plans.empty?

      quick_plans[date.cweek % quick_plans.size]
    end
  end

  def self.suggestion_context(date = Date.current)
    if FULL_SUPPLEMENTAL_WDAYS.include?(date.wday)
      "Extra toning day — Runna covers Wed/Sat strength."
    elsif RUNNA_STRENGTH_WDAYS.include?(date.wday)
      "Runna strength today — optional quick add-on after."
    elsif RUN_DAYS.include?(date.wday)
      "Optional add-on after your run."
    else
      "Light supplemental work when you have energy."
    end
  end

  def build_session_for(daily_log, location: nil)
    session = daily_log.strength_sessions.build(
      workout_plan: self,
      location: location || self.location
    )

    workout_plan_exercises.each do |exercise|
      session.strength_exercise_logs.build(
        name: exercise.name,
        equipment: exercise.equipment_hint,
        sets: exercise.sets_prescription.to_s[/\d+/]&.to_i,
        reps: exercise.reps_prescription,
        position: exercise.position,
        notes: [ exercise.sets_prescription, exercise.reps_prescription ].compact.join(" · ")
      )
    end

    session
  end
end
