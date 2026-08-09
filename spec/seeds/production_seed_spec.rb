# frozen_string_literal: true

require "rails_helper"

# `RAILS_ENV=production bin/rails db:seed` has broken on the Pi more than once.
# This runs the exact same files against the test database.
RSpec.describe "db/seeds/production.rb" do
  def load_production_seed!
    original = $RECIPES_SEED_HELPER_ONLY
    $RECIPES_SEED_HELPER_ONLY = false
    silence_stream { load Rails.root.join("db/seeds/production.rb") }
  ensure
    $RECIPES_SEED_HELPER_ONLY = original
  end

  def silence_stream
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  it "runs without raising" do
    expect { load_production_seed! }.not_to raise_error
  end

  it "is idempotent across repeated runs" do
    load_production_seed!
    counts = { recipes: Recipe.count, products: Product.count, templates: MealTemplate.count }

    load_production_seed!

    expect(Recipe.count).to eq(counts[:recipes])
    expect(Product.count).to eq(counts[:products])
    expect(MealTemplate.count).to eq(counts[:templates])
  end

  it "leaves every recipe ingredient valid" do
    load_production_seed!

    invalid = RecipeIngredient.all.reject(&:valid?)

    expect(invalid).to be_empty,
      invalid.map { |i| "#{i.recipe.slug}/#{i.name}: #{i.errors.full_messages.to_sentence}" }.join("; ")
  end

  it "seeds the Nora Cooks pancake recipe with a meal template" do
    load_production_seed!

    recipe = Recipe.find_by(slug: "noracooks-vegan-pancakes")

    expect(recipe).to be_present
    expect(recipe.meal_template).to be_present
    expect(recipe.nutrition_per_serving[:calories]).to be_positive
  end

  it "gives every recipe page the data it needs to render" do
    load_production_seed!

    Recipe.includes(:meal_template, recipe_ingredients: :product).find_each do |recipe|
      expect { RecipeMealFormBuilder.new(recipe).nutrition }.not_to raise_error
    end
  end
end
