# frozen_string_literal: true

FactoryBot.define do
  factory :progress_photo do
    daily_log
    photo_type { :front }
    caption { "Progress" }

    after(:build) do |photo|
      photo.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
    end
  end

  factory :outfit_photo do
    logged_on { Date.current }
    category { :everyday }
    caption { "Outfit" }

    after(:build) do |photo|
      photo.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
    end
  end
end
