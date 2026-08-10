# frozen_string_literal: true

class AddBodyProfileToGoals < ActiveRecord::Migration[8.0]
  def change
    add_column :goals, :height_cm, :decimal, precision: 5, scale: 1
    add_column :goals, :age_years, :integer
    add_column :goals, :sex, :string, default: "female", null: false
    add_column :goals, :activity_level, :string, default: "moderate", null: false
    add_column :goals, :target_deficit_kcal, :integer

    reversible do |dir|
      dir.up do
        # Natasha's profile — used for Mifflin–St Jeor maintenance estimates.
        execute <<~SQL
          UPDATE goals
          SET height_cm = 163.0,
              age_years = 37,
              sex = 'female',
              activity_level = 'moderate',
              target_deficit_kcal = 400
          WHERE height_cm IS NULL
        SQL
      end
    end
  end
end
