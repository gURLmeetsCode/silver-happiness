# frozen_string_literal: true

class AddLifeStageAndPregnancyFieldsToGoals < ActiveRecord::Migration[8.0]
  def change
    add_column :goals, :life_stage, :string, null: false, default: "standard"
    add_column :goals, :pre_pregnancy_weight_kg, :decimal, precision: 8, scale: 2
    add_column :goals, :pregnancy_confirmed_on, :date
    add_column :goals, :pregnancy_lmp_on, :date
    add_column :goals, :pregnancy_due_on, :date
    add_column :goals, :exercise_cleared_by_clinician, :boolean, null: false, default: false
  end
end
