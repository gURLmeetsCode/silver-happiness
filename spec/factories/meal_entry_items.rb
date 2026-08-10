# frozen_string_literal: true

FactoryBot.define do
  factory :meal_entry_item do
    meal_entry
    product
    grams { 30 }
    sequence(:position) { |n| n }
  end
end
