# frozen_string_literal: true

class AddRunDurationToDailyLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :daily_logs, :run_duration_min, :integer
  end
end
