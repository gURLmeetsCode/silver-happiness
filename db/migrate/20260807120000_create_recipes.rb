class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :meal_type, null: false, default: 0
      t.text :description
      t.text :steps
      t.string :prep_time
      t.integer :serves, default: 1
      t.integer :protein_g
      t.integer :calories
      t.boolean :regular_meal, default: true, null: false
      t.integer :position, default: 0, null: false
      t.references :meal_template, foreign_key: true

      t.timestamps
    end

    add_index :recipes, :slug, unique: true

    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :name, null: false
      t.string :amount
      t.integer :grocery_category, null: false, default: 0
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
