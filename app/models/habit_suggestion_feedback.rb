# frozen_string_literal: true

# One row per cut-nudge key. Dismiss snoozes it; not_helpful hides it for good.
class HabitSuggestionFeedback < ApplicationRecord
  SNOOZE_DAYS = 7

  enum :status, { dismissed: 0, not_helpful: 1 }

  validates :suggestion_key, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9_]+\z/ }

  def self.hidden_keys(on: Date.current)
    (
      not_helpful.pluck(:suggestion_key) +
      dismissed.where("hidden_until >= ?", on).pluck(:suggestion_key)
    ).uniq
  end

  def self.dismissed_today_keys
    dismissed.where(updated_at: Time.current.all_day).pluck(:suggestion_key)
  end

  def dismiss!
    update!(status: :dismissed, hidden_until: Date.current + SNOOZE_DAYS)
  end

  def mark_not_helpful!
    update!(status: :not_helpful, hidden_until: nil)
  end
end
