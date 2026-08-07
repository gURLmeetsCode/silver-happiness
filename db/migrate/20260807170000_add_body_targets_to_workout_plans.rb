class AddBodyTargetsToWorkoutPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_plans, :body_targets, :string
    add_column :workout_plan_exercises, :body_target, :string
  end
end
