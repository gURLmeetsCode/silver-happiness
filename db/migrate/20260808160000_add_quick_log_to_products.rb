class AddQuickLogToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :quick_log, :boolean, default: false, null: false
    add_index :products, :quick_log
  end
end
