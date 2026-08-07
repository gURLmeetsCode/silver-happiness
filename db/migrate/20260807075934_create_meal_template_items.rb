class CreateMealTemplateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_template_items do |t|
      t.references :meal_template, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity_g, precision: 8, scale: 2, null: false
      t.string :label

      t.timestamps
    end
  end
end
