class Workout < ApplicationRecord
  enum :activity_type, { run: 0, walk: 1, strength: 2, other: 3 }, prefix: true

  belongs_to :daily_log

  validates :calories_burned, numericality: { greater_than_or_equal_to: 0 }
  validates :activity_type, presence: true

  def summary
    parts = [ activity_type.humanize ]
    parts << "#{distance_km} km" if distance_km.present?
    parts << "#{calories_burned} kcal"
    parts << notes if notes.present?
    parts.compact_blank.join(" · ")
  end
end
