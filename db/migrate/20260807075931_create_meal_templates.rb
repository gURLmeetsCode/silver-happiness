class CreateMealTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_templates do |t|
      t.string :name
      t.integer :meal_type
      t.text :description
      t.string :slug

      t.timestamps
    end
    add_index :meal_templates, :slug, unique: true
  end
end
