# frozen_string_literal: true

FactoryBot.define do
  factory :goal do
    target_weight_kg { 56 }
    starting_weight_kg { 62 }
    protein_min_g { 90 }
    protein_max_g { 100 }
    calories_training_day { 1700 }
    calories_rest_day { 1600 }
    water_goal_ml { 2000 }
  end

  factory :grocery_check do
    shopping_period { ShoppingPeriod.current }
    sequence(:item_key) { |n| "item-#{n}" }
    checked { true }
  end
end
