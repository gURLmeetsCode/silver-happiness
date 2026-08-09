# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeIngredient do
  it "requires a name" do
    expect(build(:recipe_ingredient, name: nil)).not_to be_valid
  end

  it "allows an untracked ingredient with no product and no quantity" do
    expect(build(:recipe_ingredient, product: nil, quantity_g: nil)).to be_valid
  end

  it "rejects a linked product without a quantity" do
    ingredient = build(:recipe_ingredient, product: create(:product), quantity_g: nil)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:quantity_g]).to include("is required when using a saved product")
  end

  it "computes nutrition only when tracked" do
    tracked = create(:recipe_ingredient, :tracked, quantity_g: 200)
    untracked = create(:recipe_ingredient)

    expect(tracked).to be_tracked
    expect(tracked.nutrition[:calories]).to eq(200)
    expect(untracked).not_to be_tracked
    expect(untracked.nutrition).to be_nil
  end
end
