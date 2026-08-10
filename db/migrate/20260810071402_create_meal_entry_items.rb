class CreateMealEntryItems < ActiveRecord::Migration[8.0]
  def up
    create_table :meal_entry_items do |t|
      t.references :meal_entry, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :grams, precision: 8, scale: 2, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    say_with_time "Backfilling meal_entry_items from templates and notes" do
      backfill_from_templates
      backfill_from_assembler_notes
    end
  end

  def down
    drop_table :meal_entry_items
  end

  private

  def backfill_from_templates
    execute <<~SQL
      INSERT INTO meal_entry_items (meal_entry_id, product_id, grams, position, created_at, updated_at)
      SELECT me.id, mti.product_id, mti.quantity_g, mti.id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM meal_entries me
      INNER JOIN meal_template_items mti ON mti.meal_template_id = me.meal_template_id
      WHERE me.meal_template_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM meal_entry_items mei WHERE mei.meal_entry_id = me.id
        )
    SQL
  end

  # Meals assembled before this table existed wrote "0.5 cup Zucchini (120 g)" into
  # notes. Recover those amounts so yesterday's dinner can still be advised on.
  def backfill_from_assembler_notes
    products = select_all("SELECT id, name FROM products").to_a
    return if products.empty?

    by_name = products.each_with_object({}) { |row, map| map[row["name"].downcase] = row["id"] }

    select_all("SELECT id, notes FROM meal_entries WHERE notes IS NOT NULL AND notes != ''").each do |entry|
      already = select_value("SELECT COUNT(*) FROM meal_entry_items WHERE meal_entry_id = #{entry['id']}")
      next if already.to_i.positive?

      position = 0
      entry["notes"].to_s.scan(/([^·;]+?)\((\d+(?:\.\d+)?)\s*g\)/i) do |label, grams|
        name = label.to_s.sub(/\A[\d.,\/½¼¾]+\s*(?:cup|tsp|tbsp|×|x)?\s*/i, "").strip
        name = name.sub(/\A\+\s*/, "").strip
        product_id = by_name[name.downcase]
        next unless product_id

        execute <<~SQL
          INSERT INTO meal_entry_items (meal_entry_id, product_id, grams, position, created_at, updated_at)
          VALUES (#{entry['id']}, #{product_id}, #{grams.to_f}, #{position}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        SQL
        position += 1
      end
    end
  end
end
