# frozen_string_literal: true

class DropNudgeFeedbackAndGroceryChecks < ActiveRecord::Migration[8.0]
  def change
    drop_table :habit_suggestion_feedbacks, if_exists: true do |t|
      t.string :suggestion_key, null: false
      t.integer :status, null: false, default: 0
      t.date :hidden_until
      t.timestamps
      t.index :suggestion_key, unique: true
    end

    drop_table :grocery_checks, if_exists: true do |t|
      t.date :shopping_period, null: false
      t.string :item_key, null: false
      t.boolean :checked, null: false, default: false
      t.timestamps
      t.index [ :shopping_period, :item_key ], unique: true
    end
  end
end
