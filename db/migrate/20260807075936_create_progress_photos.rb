class CreateProgressPhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :progress_photos do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.integer :photo_type
      t.text :caption

      t.timestamps
    end
  end
end
