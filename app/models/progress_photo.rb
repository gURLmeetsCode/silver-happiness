class ProgressPhoto < ApplicationRecord
  enum :photo_type, { front: 0, side: 1, other: 2 }, prefix: true

  belongs_to :daily_log

  has_one_attached :image

  validates :image, presence: true
end
