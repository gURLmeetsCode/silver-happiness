# frozen_string_literal: true

# Prevent duplicate catalog rows (same name or same barcode) and one strength
# plan per day. Merges any existing name/barcode collisions before unique indexes.
class PreventDuplicateProductsAndGuards < ActiveRecord::Migration[8.0]
  def up
    say_with_time "normalize blank barcodes to NULL" do
      execute "UPDATE products SET barcode = NULL WHERE barcode IS NOT NULL AND TRIM(barcode) = ''"
    end

    say_with_time "merge duplicate products by name (case-insensitive)" do
      keys = Product.group(Arel.sql("LOWER(name)")).having("COUNT(*) > 1").pluck(Arel.sql("LOWER(name)"))
      keys.each do |key|
        merge_products!(Product.where("LOWER(name) = ?", key).order(:id).to_a)
      end
    end

    say_with_time "merge duplicate products by barcode" do
      codes = Product.where.not(barcode: nil).group(:barcode).having("COUNT(*) > 1").pluck(:barcode)
      codes.each { |code| merge_products!(Product.where(barcode: code).order(:id).to_a) }
    end

    remove_index :products, name: "index_products_on_barcode" if index_exists?(:products, :barcode, name: "index_products_on_barcode")

    add_index :products, "LOWER(name)", unique: true, name: "index_products_on_lower_name"
    add_index :products, :barcode, unique: true, name: "index_products_on_barcode_unique",
              where: "barcode IS NOT NULL"

    add_index :recipes, "LOWER(name)", unique: true, name: "index_recipes_on_lower_name"

    add_index :strength_sessions, [ :daily_log_id, :workout_plan_id ],
              unique: true,
              where: "workout_plan_id IS NOT NULL",
              name: "index_strength_sessions_unique_plan_per_day"
  end

  def down
    remove_index :strength_sessions, name: "index_strength_sessions_unique_plan_per_day"
    remove_index :recipes, name: "index_recipes_on_lower_name"
    remove_index :products, name: "index_products_on_barcode_unique"
    remove_index :products, name: "index_products_on_lower_name"
    add_index :products, :barcode, name: "index_products_on_barcode"
  end

  private

  def merge_products!(rows)
    keep = rows.shift
    rows.each do |dup|
      MealEntryItem.where(product_id: dup.id).update_all(product_id: keep.id)
      MealTemplateItem.where(product_id: dup.id).update_all(product_id: keep.id)
      RecipeIngredient.where(product_id: dup.id).update_all(product_id: keep.id)
      keep.barcode = dup.barcode if keep.barcode.blank? && dup.barcode.present?
      keep.brand = dup.brand if keep.brand.blank? && dup.brand.present?
      keep.serving_label = dup.serving_label if keep.serving_label.blank? && dup.serving_label.present?
      keep.default_serving_g = dup.default_serving_g if keep.default_serving_g.blank? && dup.default_serving_g.present?
      if dup.notes.present?
        keep.notes = [ keep.notes, dup.notes ].compact_blank.uniq.join(" · ")
      end
      keep.save! if keep.changed?
      dup.destroy!
    end
  end
end
