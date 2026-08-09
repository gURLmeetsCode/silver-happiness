# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    calories_per_100g { 100 }
    protein_per_100g { 10 }
    carbs_per_100g { 5 }
    fat_per_100g { 2 }

    trait :quick_log do
      quick_log { true }
      default_serving_g { 100 }
    end

    trait :beverage do
      quick_log { true }
      beverage { true }
      default_serving_g { 100 }
      water_volume_ml { 500 }
    end

    factory :quick_product, traits: [ :quick_log ]
    factory :beverage_product, traits: [ :beverage ]
  end
end
