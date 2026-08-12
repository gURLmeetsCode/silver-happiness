# frozen_string_literal: true

class CreateUrgeCheckInsAndHardDayDebrief < ActiveRecord::Migration[8.0]
  def change
    create_table :urge_check_ins do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.string :feeling, null: false
      t.string :protein_status, null: false
      t.string :delay_action, null: false
      t.string :outcome, null: false
      t.text :note

      t.timestamps
    end

    add_index :urge_check_ins, [ :daily_log_id, :created_at ]

    change_table :daily_logs, bulk: true do |t|
      t.text :hard_day_trigger
      t.text :hard_day_what_was_available
      t.text :hard_day_next_time
    end
  end
end
