# frozen_string_literal: true

class CreateGroceryChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :grocery_checks do |t|
      t.date :shopping_period, null: false
      t.string :item_key, null: false
      t.boolean :checked, null: false, default: false

      t.timestamps
    end

    add_index :grocery_checks, [ :shopping_period, :item_key ], unique: true
  end
end
