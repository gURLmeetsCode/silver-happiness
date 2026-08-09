# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application time zone" do
  it "runs in the zone you actually live in" do
    expect(Time.zone.name).to eq("Europe/Paris")
  end

  # The Pi's OS clock is set to US Eastern. If the app ever falls back to the
  # host zone, "today" moves and meals land on the wrong day.
  it "does not depend on the host clock" do
    expect(Rails.application.config.time_zone).to eq("Europe/Paris")
  end

  describe "wall-clock time columns" do
    # Bed time is a reading, not an instant. Zone-converting it would shift
    # every sleep record already in the database by the UTC offset.
    it "keeps time columns out of zone conversion" do
      expect(ActiveRecord::Base.time_zone_aware_types).to eq([ :datetime ])
    end

    it "reads back the exact time that was written" do
      log = create(:daily_log, bed_time: "22:30", wake_time: "06:15")
      log.reload

      expect(log.bed_time.strftime("%H:%M")).to eq("22:30")
      expect(log.wake_time.strftime("%H:%M")).to eq("06:15")
    end
  end

  describe "the greeting" do
    it "says afternoon at noon local time" do
      travel_to Time.zone.local(2026, 8, 9, 12, 10) do
        expect(helper_greeting).to eq("Good afternoon")
      end
    end

    it "says morning at 9am local time" do
      travel_to Time.zone.local(2026, 8, 9, 9, 0) do
        expect(helper_greeting).to eq("Good morning")
      end
    end

    it "says evening at 8pm local time" do
      travel_to Time.zone.local(2026, 8, 9, 20, 0) do
        expect(helper_greeting).to eq("Good evening")
      end
    end
  end

  def helper_greeting
    Class.new { include ApplicationHelper }.new.time_of_day_greeting
  end
end
