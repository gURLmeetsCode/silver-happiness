# frozen_string_literal: true

class CreateHabitSuggestionFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :habit_suggestion_feedbacks do |t|
      t.string :suggestion_key, null: false
      t.integer :status, null: false, default: 0
      t.date :hidden_until
      t.timestamps
    end

    add_index :habit_suggestion_feedbacks, :suggestion_key, unique: true
  end
end
