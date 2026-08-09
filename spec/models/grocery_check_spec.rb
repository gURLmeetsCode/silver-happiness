# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroceryCheck do
  let(:period) { Date.new(2026, 8, 5) }

  it "checks an item on first toggle" do
    expect(described_class.toggle!(period: period, item_key: "staple:produce:abc")).to be true
    expect(described_class.checked?(period: period, item_key: "staple:produce:abc")).to be true
  end

  it "unchecks on the second toggle" do
    described_class.toggle!(period: period, item_key: "staple:produce:abc")

    expect(described_class.toggle!(period: period, item_key: "staple:produce:abc")).to be false
  end

  it "scopes checks to their shopping period" do
    described_class.create!(shopping_period: period, item_key: "item-1", checked: true)

    expect(described_class.checked?(period: Date.new(2026, 8, 9), item_key: "item-1")).to be false
  end
end
