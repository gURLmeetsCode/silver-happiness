# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    calories_per_100g { 100 }
    protein_per_100g { 10 }
    carbs_per_100g { 5 }
    fat_per_100g { 2 }
    default_serving_g { 100 }

    trait :beverage do
      beverage { true }
      water_volume_ml { 500 }
    end

    factory :beverage_product, traits: [ :beverage ]
  end
end
