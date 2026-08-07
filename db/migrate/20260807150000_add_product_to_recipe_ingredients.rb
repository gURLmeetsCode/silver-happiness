class AddProductToRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    change_table :recipe_ingredients, bulk: true do |t|
      t.references :product, foreign_key: true
      t.decimal :quantity_g, precision: 8, scale: 2
    end
  end
end
