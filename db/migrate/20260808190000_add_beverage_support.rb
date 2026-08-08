# frozen_string_literal: true

class AddBeverageSupport < ActiveRecord::Migration[8.0]
  def up
    change_table :products, bulk: true do |t|
      t.boolean :beverage, default: false, null: false
      t.integer :water_volume_ml
    end

    add_index :products, :beverage

    # Backfill known drinks from seeds / common quick-log items.
    execute <<~SQL.squish
      UPDATE products
      SET beverage = 1
      WHERE quick_log = 1
        AND (
          name LIKE '%Coca-Cola%'
          OR name LIKE '%Coke%'
          OR name LIKE '%water%'
          OR name LIKE '%Volvic%'
          OR name LIKE '%Eau%'
        )
    SQL

    execute <<~SQL.squish
      UPDATE products
      SET water_volume_ml = CAST(default_serving_g AS INTEGER)
      WHERE beverage = 1
        AND water_volume_ml IS NULL
        AND (
          name LIKE '%water%'
          OR name LIKE '%Volvic%'
          OR name LIKE '%Eau%'
          OR calories_per_100g = 0 AND default_serving_g BETWEEN 100 AND 2000
        )
    SQL
  end

  def down
    change_table :products, bulk: true do |t|
      t.remove :water_volume_ml
      t.remove :beverage
    end
  end
end
