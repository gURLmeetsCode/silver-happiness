# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutfitPhoto, type: :model do
  describe ".daily_inspo_for" do
    it "returns nil when there are no outfit photos" do
      expect(described_class.daily_inspo_for).to be_nil
    end

    it "returns the only photo every day when there is one" do
      photo = create(:outfit_photo, caption: "Only look")

      expect(described_class.daily_inspo_for(Date.new(2026, 8, 12))).to eq(photo)
      expect(described_class.daily_inspo_for(Date.new(2026, 8, 13))).to eq(photo)
    end

    it "is stable for a given date and can change across days" do
      first = create(:outfit_photo, caption: "First", logged_on: Date.new(2026, 8, 1))
      second = create(:outfit_photo, caption: "Second", logged_on: Date.new(2026, 8, 2))
      ids = [ first.id, second.id ].sort
      earlier = described_class.find(ids.first)
      later = described_class.find(ids.last)

      day_a = Date.new(2026, 1, 1) # yday 1 → index 1
      day_b = Date.new(2026, 1, 2) # yday 2 → index 0

      expect(described_class.daily_inspo_for(day_a)).to eq(later)
      expect(described_class.daily_inspo_for(day_a)).to eq(described_class.daily_inspo_for(day_a))
      expect(described_class.daily_inspo_for(day_b)).to eq(earlier)
      expect(described_class.daily_inspo_for(day_a)).not_to eq(described_class.daily_inspo_for(day_b))
    end
  end

  describe ".daily_inspo_alternate" do
    it "returns nil with fewer than two photos" do
      photo = create(:outfit_photo)

      expect(described_class.daily_inspo_alternate(photo)).to be_nil
      expect(described_class.daily_inspo_alternate(nil)).to be_nil
    end

    it "returns the other photo in the daily rotation" do
      first = create(:outfit_photo, caption: "First")
      second = create(:outfit_photo, caption: "Second")
      date = Date.new(2026, 1, 1)
      featured = described_class.daily_inspo_for(date)
      alt = described_class.daily_inspo_alternate(featured, date)

      expect(alt).to eq([ first, second ].find { |photo| photo != featured })
    end
  end
end
