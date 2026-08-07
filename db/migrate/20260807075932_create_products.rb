class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :brand
      t.decimal :calories_per_100g, precision: 8, scale: 2, default: 0
      t.decimal :protein_per_100g, precision: 8, scale: 2, default: 0
      t.decimal :carbs_per_100g, precision: 8, scale: 2, default: 0
      t.decimal :fat_per_100g, precision: 8, scale: 2, default: 0
      t.decimal :default_serving_g, precision: 8, scale: 2
      t.string :serving_label
      t.text :notes

      t.timestamps
    end
  end
end
