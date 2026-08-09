# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  it "requires a name and per-100g macros" do
    product = described_class.new

    expect(product).not_to be_valid
    expect(product.errors[:name]).to be_present
  end

  it "requires a default serving for quick-log products" do
    product = build(:product, quick_log: true, default_serving_g: nil)

    expect(product).not_to be_valid
    expect(product.errors[:default_serving_g]).to be_present
  end

  it "scales nutrition by grams" do
    product = build(:product, calories_per_100g: 100, protein_per_100g: 10)

    expect(product.nutrition_for(250)[:calories]).to eq(250)
    expect(product.nutrition_for(250)[:protein]).to eq(25)
  end

  describe "scopes" do
    it "separates quick-log beverages from snacks" do
      beverage = create(:beverage_product)
      snack = create(:quick_product)
      create(:product)

      expect(described_class.quick_log_beverages).to contain_exactly(beverage)
      expect(described_class.quick_log_snacks).to contain_exactly(snack)
    end
  end
end
