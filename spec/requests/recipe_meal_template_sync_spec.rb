# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipe meal template sync", type: :request do
  before { Goal.current }

  it "makes a new recipe available in Build a meal" do
    chickpeas = create(:product, name: "Chickpeas cooked", default_serving_g: 100,
      calories_per_100g: 164, protein_per_100g: 9)

    expect {
      post recipes_path, params: {
        recipe: {
          name: "Oil-free hummus",
          meal_type: "snack",
          serves: 4,
          regular_meal: true,
          recipe_ingredients_attributes: {
            "0" => {
              name: chickpeas.name,
              amount: "400 g",
              grocery_category: "protein",
              product_id: chickpeas.id,
              quantity_g: 400,
              position: 0
            }
          }
        }
      }
    }.to change(Recipe, :count).by(1)
      .and change(MealTemplate, :count).by(1)

    recipe = Recipe.find_by!(name: "Oil-free hummus")
    expect(recipe.meal_template).to be_present
    expect(recipe.meal_template.meal_template_items.first.product).to eq(chickpeas)

    get daily_log_path(DailyLog.today)
    expect(response.body).to include("Oil-free hummus")
    expect(response.body).to include("template_#{recipe.meal_template_id}")
  end
end
