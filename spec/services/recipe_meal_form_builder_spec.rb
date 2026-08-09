# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeMealFormBuilder do
  it "suggests the globally seeded extras" do
    sauce = create(:product, name: "Cholula Chipotle sauce")
    recipe = create(:recipe)

    expect(described_class.new(recipe).suggested_products).to include(sauce)
  end

  it "suggests pancake toppings for the Nora Cooks recipe" do
    skyr = create(:product, name: "Skyr vegan")
    berries = create(:product, name: "Strawberries")
    recipe = create(:recipe, slug: "noracooks-vegan-pancakes")

    expect(described_class.new(recipe).suggested_products).to include(skyr, berries)
  end

  it "caps suggestions at the number of extra rows" do
    described_class::SUGGESTED_PRODUCT_NAMES.each { |name| create(:product, name: name) }
    recipe = create(:recipe)
    create(:recipe_ingredient, :tracked, recipe: recipe)

    expect(described_class.new(recipe).suggested_products.size).to eq(described_class::EXTRA_ROWS)
  end

  it "infers servings from an existing entry's calories" do
    recipe = create(:recipe, serves: 1)
    create(:recipe_ingredient, :tracked, recipe: recipe, quantity_g: 100)
    recipe.reload
    per = recipe.nutrition_per_serving[:calories]
    entry = build(:meal_entry, calories: per * 3)

    expect(described_class.new(recipe, entry: entry).inferred_servings).to eq(3)
  end

  it "defaults to one serving with no entry" do
    expect(described_class.new(create(:recipe)).inferred_servings).to eq(1)
  end
end
