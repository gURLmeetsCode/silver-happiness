# frozen_string_literal: true

FactoryBot.define do
  factory :workout do
    daily_log
    activity_type { :strength }
    calories_burned { 150 }
  end

  factory :workout_plan do
    sequence(:name) { |n| "Plan #{n}" }
    sequence(:slug) { |n| "plan-#{n}" }
    location { :home }
    plan_kind { :supplemental_quick }
    description { "A supplemental strength plan." }

    trait :with_exercises do
      after(:create) do |plan|
        create(:workout_plan_exercise, workout_plan: plan)
      end
    end

    trait :runna do
      plan_kind { :runna_reference }
      location { :runna_app }
    end
  end

  factory :workout_plan_exercise do
    workout_plan
    sequence(:name) { |n| "Exercise #{n}" }
    sets_prescription { "3" }
    reps_prescription { "10" }
  end

  factory :strength_session do
    daily_log
    location { :home }
    perceived_difficulty { 5 }
    duration_min { 30 }
    calories_burned { 185 }

    trait :with_logs do
      after(:create) do |session|
        create(:strength_exercise_log, strength_session: session)
      end
    end
  end

  factory :strength_exercise_log do
    strength_session
    sequence(:name) { |n| "Lift #{n}" }
    sets { 3 }
    reps { "10" }
    weight_kg { 12.5 }
  end
end
