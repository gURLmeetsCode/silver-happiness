class AddWellnessToDailyLogs < ActiveRecord::Migration[8.0]
  def change
    change_table :daily_logs, bulk: true do |t|
      t.boolean :on_period, default: false, null: false
      t.integer :water_ml, default: 0, null: false
      t.time :bed_time
      t.time :wake_time
      t.integer :sleep_quality
      t.text :feeling_check_in
    end

    add_column :goals, :water_goal_ml, :integer, default: 2000, null: false
  end
end
