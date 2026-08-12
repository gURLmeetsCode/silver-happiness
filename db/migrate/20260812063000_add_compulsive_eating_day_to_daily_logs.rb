# frozen_string_literal: true

class AddCompulsiveEatingDayToDailyLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :daily_logs, :compulsive_eating_day, :boolean, default: false, null: false
  end
end
