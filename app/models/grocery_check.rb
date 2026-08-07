# frozen_string_literal: true

class GroceryCheck < ApplicationRecord
  validates :shopping_period, presence: true
  validates :item_key, presence: true, uniqueness: { scope: :shopping_period }

  scope :for_period, ->(period) { where(shopping_period: period) }
  scope :checked, -> { where(checked: true) }

  def self.checked_keys_for(period)
    for_period(period).checked.pluck(:item_key).to_set
  end

  def self.checked?(period:, item_key:)
    for_period(period).checked.exists?(item_key: item_key)
  end

  def self.toggle!(period:, item_key:)
    record = find_or_initialize_by(shopping_period: period, item_key: item_key)
    record.checked = !record.checked
    record.save!
    record.checked
  end

  def self.staple_key(category, label)
    "staple:#{category}:#{Digest::SHA256.hexdigest(label)[0, 12]}"
  end
end
