# frozen_string_literal: true

# Prevent duplicate catalog rows (same name or same barcode) and one strength
# plan per day. Merges any existing collisions before adding unique indexes.
#
# Important: while twins still exist, do NOT Product#save! (uniqueness
# validations will reject the keeper). Use update_columns + delete instead.
class PreventDuplicateProductsAndGuards < ActiveRecord::Migration[8.0]
  def up
    say_with_time "normalize blank barcodes and trim names" do
      execute "UPDATE products SET barcode = NULL WHERE barcode IS NOT NULL AND TRIM(barcode) = ''"
      execute "UPDATE products SET name = TRIM(name) WHERE name != TRIM(name)"
      execute "UPDATE recipes SET name = TRIM(name) WHERE name != TRIM(name)"
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

    say_with_time "rename case-insensitive duplicate recipe names" do
      keys = Recipe.group(Arel.sql("LOWER(name)")).having("COUNT(*) > 1").pluck(Arel.sql("LOWER(name)"))
      keys.each do |key|
        rows = Recipe.where("LOWER(name) = ?", key).order(:id).to_a
        rows.drop(1).each do |dup|
          dup.update_columns(name: "#{dup.name} (copy #{dup.id})")
        end
      end
    end

    say_with_time "drop duplicate strength sessions for the same plan/day" do
      pairs = StrengthSession.where.not(workout_plan_id: nil)
        .group(:daily_log_id, :workout_plan_id)
        .having("COUNT(*) > 1")
        .pluck(:daily_log_id, :workout_plan_id)
      pairs.each do |daily_log_id, workout_plan_id|
        rows = StrengthSession.where(daily_log_id: daily_log_id, workout_plan_id: workout_plan_id).order(:id).to_a
        rows.drop(1).each { |dup| StrengthExerciseLog.where(strength_session_id: dup.id).delete_all; dup.delete }
      end
    end

    remove_index :products, name: "index_products_on_barcode" if index_exists?(:products, :barcode, name: "index_products_on_barcode")

    add_index :products, "LOWER(name)", unique: true, name: "index_products_on_lower_name" unless index_exists?(:products, name: "index_products_on_lower_name")
    unless index_exists?(:products, name: "index_products_on_barcode_unique")
      add_index :products, :barcode, unique: true, name: "index_products_on_barcode_unique",
                where: "barcode IS NOT NULL"
    end

    add_index :recipes, "LOWER(name)", unique: true, name: "index_recipes_on_lower_name" unless index_exists?(:recipes, name: "index_recipes_on_lower_name")

    unless index_exists?(:strength_sessions, name: "index_strength_sessions_unique_plan_per_day")
      add_index :strength_sessions, [ :daily_log_id, :workout_plan_id ],
                unique: true,
                where: "workout_plan_id IS NOT NULL",
                name: "index_strength_sessions_unique_plan_per_day"
    end
  end

  def down
    remove_index :strength_sessions, name: "index_strength_sessions_unique_plan_per_day" if index_exists?(:strength_sessions, name: "index_strength_sessions_unique_plan_per_day")
    remove_index :recipes, name: "index_recipes_on_lower_name" if index_exists?(:recipes, name: "index_recipes_on_lower_name")
    remove_index :products, name: "index_products_on_barcode_unique" if index_exists?(:products, name: "index_products_on_barcode_unique")
    remove_index :products, name: "index_products_on_lower_name" if index_exists?(:products, name: "index_products_on_lower_name")
    add_index :products, :barcode, name: "index_products_on_barcode" unless index_exists?(:products, :barcode, name: "index_products_on_barcode")
  end

  private

  def merge_products!(rows)
    keep = rows.shift
    rows.each do |dup|
      MealEntryItem.where(product_id: dup.id).update_all(product_id: keep.id)
      MealTemplateItem.where(product_id: dup.id).update_all(product_id: keep.id)
      RecipeIngredient.where(product_id: dup.id).update_all(product_id: keep.id)

      attrs = {}
      attrs[:barcode] = dup.barcode if keep.barcode.blank? && dup.barcode.present?
      attrs[:brand] = dup.brand if keep.brand.blank? && dup.brand.present?
      attrs[:serving_label] = dup.serving_label if keep.serving_label.blank? && dup.serving_label.present?
      attrs[:default_serving_g] = dup.default_serving_g if keep.default_serving_g.blank? && dup.default_serving_g.present?
      if dup.notes.present?
        attrs[:notes] = [ keep.notes, dup.notes ].compact_blank.uniq.join(" · ")
      end

      # Delete the twin first so unique indexes / validations cannot reject the keeper.
      dup.delete
      keep.update_columns(attrs) if attrs.any?
      keep.reload if attrs.any?
    end
  end
end
