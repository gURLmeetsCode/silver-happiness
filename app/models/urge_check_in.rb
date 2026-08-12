# frozen_string_literal: true

# A short pause between "I want to spiral" and eating — not judgment, just data
# for what was going on and whether a tiny delay helped.
class UrgeCheckIn < ApplicationRecord
  belongs_to :daily_log

  FEELINGS = {
    "hungry" => "Actually hungry",
    "stressed" => "Stressed / anxious",
    "bored" => "Bored",
    "lonely" => "Lonely",
    "already_ruined" => "“Already ruined the day”",
    "tired" => "Tired / depleted"
  }.freeze

  PROTEIN_STATUSES = {
    "yes" => "Protein looks ok today",
    "no" => "Protein is low so far",
    "unsure" => "Not sure"
  }.freeze

  DELAY_ACTIONS = {
    "tea" => "Make tea / drink water",
    "walk" => "Walk 5 minutes",
    "brush_teeth" => "Brush teeth",
    "text" => "Text someone",
    "wait" => "Wait 10 minutes"
  }.freeze

  OUTCOMES = {
    "paused" => "Logged the urge — didn’t binge",
    "ate_anyway" => "Ate anyway (still useful to log)"
  }.freeze

  validates :feeling, inclusion: { in: FEELINGS.keys }
  validates :protein_status, inclusion: { in: PROTEIN_STATUSES.keys }
  validates :delay_action, inclusion: { in: DELAY_ACTIONS.keys }
  validates :outcome, inclusion: { in: OUTCOMES.keys }

  scope :recent, -> { order(created_at: :desc) }

  def feeling_label
    FEELINGS[feeling] || feeling.humanize
  end

  def protein_status_label
    PROTEIN_STATUSES[protein_status] || protein_status.humanize
  end

  def delay_action_label
    DELAY_ACTIONS[delay_action] || delay_action.humanize
  end

  def outcome_label
    OUTCOMES[outcome] || outcome.humanize
  end

  def paused?
    outcome == "paused"
  end
end
