# frozen_string_literal: true

FactoryBot.define do
  factory :meal_template do
    sequence(:name) { |n| "Template #{n}" }
    sequence(:slug) { |n| "template-#{n}" }
    meal_type { :breakfast }

    trait :with_items do
      transient do
        item_count { 2 }
      end

      after(:create) do |template, evaluator|
        evaluator.item_count.times do
          create(:meal_template_item, meal_template: template)
        end
      end
    end
  end

  factory :meal_template_item do
    meal_template
    product
    quantity_g { 100 }
    label { "portion" }
  end

  factory :meal_entry do
    daily_log
    sequence(:name) { |n| "Meal #{n}" }
    meal_type { :breakfast }
    calories { 300 }
    protein_g { 20 }
    carbs_g { 30 }
    fat_g { 10 }

    trait :beverage do
      meal_type { :beverage }
      calories { 0 }
      protein_g { 0 }
    end
  end
end
