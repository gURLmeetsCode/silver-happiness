class WorkoutPlanExercise < ApplicationRecord
  belongs_to :workout_plan

  validates :name, presence: true
end
