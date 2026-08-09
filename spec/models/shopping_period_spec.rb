# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShoppingPeriod do
  describe ".current" do
    it "returns Tuesday when today is the Friday after" do
      expect(described_class.current(on: Date.new(2026, 8, 7))).to eq(Date.new(2026, 8, 4))
    end

    it "returns today when today is a shopping day" do
      saturday = Date.new(2026, 8, 8)

      expect(described_class.current(on: saturday)).to eq(saturday)
    end

    it "returns Saturday when today is Sunday" do
      expect(described_class.current(on: Date.new(2026, 8, 9))).to eq(Date.new(2026, 8, 8))
    end
  end

  describe ".next" do
    it "returns Saturday after a Friday" do
      expect(described_class.next(on: Date.new(2026, 8, 7))).to eq(Date.new(2026, 8, 8))
    end

    it "returns Tuesday after a Saturday" do
      expect(described_class.next(on: Date.new(2026, 8, 8))).to eq(Date.new(2026, 8, 11))
    end
  end
end
