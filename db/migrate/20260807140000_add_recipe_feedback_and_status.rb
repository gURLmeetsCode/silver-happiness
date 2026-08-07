class AddRecipeFeedbackAndStatus < ActiveRecord::Migration[8.0]
  def change
    change_table :recipes, bulk: true do |t|
      t.integer :reaction, default: 0, null: false
      t.text :personal_notes
      t.integer :status, default: 0, null: false
      t.boolean :user_created, default: false, null: false
    end
  end
end
