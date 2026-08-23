# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  it "requires a name and per-100g macros" do
    product = described_class.new

    expect(product).not_to be_valid
    expect(product.errors[:name]).to be_present
  end

  it "scales nutrition by grams" do
    product = build(:product, calories_per_100g: 100, protein_per_100g: 10)

    expect(product.nutrition_for(250)[:calories]).to eq(250)
    expect(product.nutrition_for(250)[:protein]).to eq(25)
  end

  it "rejects water volume on a non-beverage" do
    product = build(:product, beverage: false, water_volume_ml: 500)

    expect(product).not_to be_valid
    expect(product.errors[:water_volume_ml]).to be_present
  end
end
