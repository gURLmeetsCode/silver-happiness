# frozen_string_literal: true

FactoryBot.define do
  factory :daily_log do
    sequence(:logged_on) { |n| Date.current - n.days }

    trait :with_run do
      run_km { 8 }
      run_calories { 448 }
    end

    trait :with_sleep do
      bed_time { Time.zone.parse("22:30") }
      wake_time { Time.zone.parse("06:15") }
      sleep_quality { 7 }
    end

    trait :weighed do
      weight_kg { 60.5 }
    end
  end
end
