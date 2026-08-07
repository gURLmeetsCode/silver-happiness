# frozen_string_literal: true

class CreateOutfitPhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :outfit_photos do |t|
      t.date :logged_on, null: false
      t.integer :category, null: false, default: 0
      t.text :caption
      t.text :note

      t.timestamps
    end

    add_index :outfit_photos, [ :logged_on, :category ]
  end
end
