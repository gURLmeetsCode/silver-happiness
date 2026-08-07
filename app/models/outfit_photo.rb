class OutfitPhoto < ApplicationRecord
  enum :category, {
    workout: 0,
    everyday: 1,
    feeling_cute: 2,
    reality_check: 3
  }, prefix: true

  has_one_attached :image

  validates :logged_on, :category, presence: true
  validates :image, presence: true

  scope :recent, -> { order(logged_on: :desc, created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  CATEGORY_LABELS = {
    "workout" => "Workout fit",
    "everyday" => "Everyday outfit",
    "feeling_cute" => "Feeling cute",
    "reality_check" => "Not as bad as you think"
  }.freeze

  CATEGORY_HINTS = {
    "workout" => "Capture gym or run looks you feel strong in.",
    "everyday" => "Regular clothes — how they actually fit today.",
    "feeling_cute" => "The mirror moment when you feel good. Keep it.",
    "reality_check" => "Snap back to reality — gentle proof your brain is lying on bad days."
  }.freeze

  def category_label
    CATEGORY_LABELS[category] || category.humanize
  end

  def category_hint
    CATEGORY_HINTS[category] || ""
  end
end
