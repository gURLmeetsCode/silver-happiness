class StrengthSession < ApplicationRecord
  enum :location, { home: 0, gym: 1, runna_app: 2 }, prefix: true

  belongs_to :daily_log
  belongs_to :workout_plan, optional: true
  has_many :strength_exercise_logs, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :strength_exercise_logs, allow_destroy: true

  validates :location, presence: true
  validates :perceived_difficulty, inclusion: { in: 1..10 }, allow_nil: true

  def title
    workout_plan&.name || "Strength session"
  end

  def location_label
    WorkoutPlan::LOCATION_LABELS[location] || location.humanize
  end

  def difficulty_label
    return "—" if perceived_difficulty.nil?

    labels = {
      1 => "1 — Very easy",
      2 => "2 — Easy",
      3 => "3 — Light",
      4 => "4 — Moderate-light",
      5 => "5 — Moderate",
      6 => "6 — Moderate-hard",
      7 => "7 — Hard",
      8 => "8 — Very hard",
      9 => "9 — Near max",
      10 => "10 — Max effort"
    }
    labels[perceived_difficulty] || perceived_difficulty.to_s
  end
end
