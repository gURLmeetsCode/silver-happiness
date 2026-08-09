# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#time_of_day_greeting" do
    {
      "05:00" => "Good morning",
      "09:30" => "Good morning",
      "12:00" => "Good afternoon",
      "17:59" => "Good afternoon",
      "18:00" => "Good evening",
      "21:59" => "Good evening",
      "23:30" => "Still up",
      "03:00" => "Still up"
    }.each do |clock, expected|
      it "returns #{expected.inspect} at #{clock}" do
        expect(helper.time_of_day_greeting(Time.zone.parse(clock))).to eq(expected)
      end
    end
  end

  describe "#home_greeting" do
    it "includes the name when one is set" do
      goal = build(:goal, display_name: "Natasha")

      expect(helper.home_greeting(goal, Time.zone.parse("09:00"))).to eq("Good morning, Natasha")
    end

    it "omits the comma when no name is set" do
      goal = build(:goal, display_name: nil)

      expect(helper.home_greeting(goal, Time.zone.parse("09:00"))).to eq("Good morning")
    end

    it "handles a missing goal" do
      expect(helper.home_greeting(nil, Time.zone.parse("09:00"))).to eq("Good morning")
    end
  end
end
