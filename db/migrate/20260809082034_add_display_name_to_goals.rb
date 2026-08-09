class AddDisplayNameToGoals < ActiveRecord::Migration[8.0]
  def change
    add_column :goals, :display_name, :string
  end
end
