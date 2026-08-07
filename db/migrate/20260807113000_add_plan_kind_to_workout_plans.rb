class AddPlanKindToWorkoutPlans < ActiveRecord::Migration[8.0]
  def up
    add_column :workout_plans, :plan_kind, :integer, default: 0, null: false
    add_column :workout_plans, :suggested_wday, :integer

    say_with_time "Backfill plan kinds" do
      WorkoutPlan.reset_column_information
      WorkoutPlan.where(slug: %w[wednesday-home saturday-gym runna-strength]).update_all(plan_kind: 0)
      WorkoutPlan.where(slug: "core-quick").update_all(plan_kind: 1)
    end
  end

  def down
    remove_column :workout_plans, :suggested_wday
    remove_column :workout_plans, :plan_kind
  end
end
