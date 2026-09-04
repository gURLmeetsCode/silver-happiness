# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProteinGapSuggestions do
  before { Goal.current.update!(protein_min_g: 90, protein_max_g: 100) }

  let(:log) { create(:daily_log) }

  it "returns no picks when the protein min is already met" do
    log.meal_entries.create!(name: "Bowl", meal_type: :lunch, calories: 500, protein_g: 95)

    result = described_class.call(daily_log: log)

    expect(result.met_min).to be true
    expect(result.grams_left).to eq(0)
    expect(result.picks).to be_empty
  end

  it "suggests high-protein staple products when short" do
    create(:product, name: "Tofu", calories_per_100g: 145, protein_per_100g: 16, default_serving_g: 125, quick_log: true)
    create(:product, name: "Crackers", calories_per_100g: 400, protein_per_100g: 5, default_serving_g: 30)

    result = described_class.call(daily_log: log, limit: 3)

    expect(result.met_min).to be false
    expect(result.grams_left).to eq(90)
    expect(result.picks.map(&:label)).to include("Tofu")
    expect(result.picks.map(&:label)).not_to include("Crackers")
  end

  it "includes active high-protein recipes" do
    create(:product, name: "Tofu", calories_per_100g: 145, protein_per_100g: 16, default_serving_g: 200)
    recipe = create(:recipe, :with_ingredients, name: "Tofu bowl", status: :active, serves: 1)
    # Ensure recipe has enough protein via tracked ingredients if factory provides them
    recipe.recipe_ingredients.destroy_all
    tofu = Product.find_by!(name: "Tofu")
    recipe.recipe_ingredients.create!(name: "Tofu", product: tofu, quantity_g: 200, grocery_category: :protein)

    result = described_class.call(daily_log: log, limit: 5)

    expect(result.picks.map(&:label)).to include("Tofu bowl").or include("Tofu")
  end
end
