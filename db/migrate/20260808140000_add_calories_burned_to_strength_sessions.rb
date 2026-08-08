class AddCaloriesBurnedToStrengthSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :strength_sessions, :calories_burned, :integer
  end
end
