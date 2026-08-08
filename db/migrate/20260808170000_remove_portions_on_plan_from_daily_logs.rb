class RemovePortionsOnPlanFromDailyLogs < ActiveRecord::Migration[8.0]
  def change
    remove_column :daily_logs, :portions_on_plan, :integer, default: 0, null: false
  end
end
