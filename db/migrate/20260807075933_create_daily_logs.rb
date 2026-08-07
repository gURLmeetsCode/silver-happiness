class CreateDailyLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_logs do |t|
      t.date :logged_on, null: false
      t.decimal :weight_kg, precision: 8, scale: 2
      t.boolean :weight_pre_run, default: true, null: false
      t.decimal :run_km, precision: 8, scale: 2
      t.integer :run_calories
      t.decimal :walk_km, precision: 8, scale: 2
      t.integer :walk_calories
      t.text :training_notes
      t.text :notes
      t.integer :portions_on_plan, default: 0, null: false
      t.text :energy_notes

      t.timestamps
    end

    add_index :daily_logs, :logged_on, unique: true
  end
end
