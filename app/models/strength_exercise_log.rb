class StrengthExerciseLog < ApplicationRecord
  belongs_to :strength_session

  validates :name, presence: true
end
