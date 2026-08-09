# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipes", type: :request do
  describe "GET /recipes" do
    it "lists visible recipes" do
      active = create(:recipe, regular_meal: true)
      archived = create(:recipe, :archived)

      get recipes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(active.name)
      expect(response.body).not_to include(archived.name)
    end

    it "includes archived recipes when asked" do
      archived = create(:recipe, :archived)

      get recipes_path, params: { show_archived: "1" }

      expect(response.body).to include(archived.name)
    end

    it "filters by meal type" do
      dinner = create(:recipe, meal_type: :dinner, regular_meal: true)
      breakfast = create(:recipe, meal_type: :breakfast, regular_meal: true)

      get recipes_path, params: { filter: "dinner" }

      expect(response.body).to include(dinner.name)
      expect(response.body).not_to include(breakfast.name)
    end

    it "ignores an unknown filter" do
      recipe = create(:recipe, regular_meal: true)

      get recipes_path, params: { filter: "not-a-meal-type" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(recipe.name)
    end
  end

  describe "GET /recipes/:id" do
    it "renders a recipe" do
      recipe = create(:recipe, :with_ingredients)

      get recipe_path(recipe)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(recipe.name)
    end

    it "renders a recipe that has a meal template log form" do
      recipe = create(:recipe, :with_ingredients, :with_template)

      get recipe_path(recipe)

      expect(response).to have_http_status(:ok)
    end

    # Regression: a deleted recipe used to surface as a 500 via the catch-all
    # StandardError handler instead of a 404.
    it "returns 404 for a recipe id that no longer exists" do
      recipe = create(:recipe)
      id = recipe.id
      recipe.destroy!

      get recipe_path(id: id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /recipes/new" do
    it "renders the new recipe form" do
      get new_recipe_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /recipes" do
    it "creates a user recipe with ingredients" do
      expect {
        post recipes_path, params: {
          recipe: {
            name: "My dinner",
            meal_type: "dinner",
            serves: 2,
            recipe_ingredients_attributes: {
              "0" => { name: "Tofu", amount: "200 g", grocery_category: "protein", position: 0 }
            }
          }
        }
      }.to change(Recipe, :count).by(1)

      expect(response).to redirect_to(Recipe.last)
      expect(Recipe.last).to be_user_created
    end

    it "re-renders with 422 when the recipe has no ingredients" do
      post recipes_path, params: { recipe: { name: "Empty", meal_type: "dinner" } }

      expect(response).to have_http_status(422)
    end
  end

  describe "GET /recipes/:id/edit" do
    it "renders the form for a user-created recipe" do
      recipe = create(:recipe, :user_created, :with_ingredients)

      get edit_recipe_path(recipe)

      expect(response).to have_http_status(:ok)
    end

    it "redirects to the recipe for a seeded one" do
      recipe = create(:recipe, :with_ingredients)

      get edit_recipe_path(recipe)

      expect(response).to redirect_to(recipe_path(recipe))
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /recipes/:id" do
    it "updates a user-created recipe" do
      recipe = create(:recipe, :user_created, :with_ingredients)

      patch recipe_path(recipe), params: { recipe: { name: "Renamed" } }

      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.reload.name).to eq("Renamed")
    end

    it "saves personal notes on a seeded recipe" do
      recipe = create(:recipe, :with_ingredients)

      patch recipe_path(recipe), params: { recipe: { personal_notes: "Use less oil" } }

      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.reload.personal_notes).to eq("Use less oil")
    end

    it "re-renders with 422 when a user recipe becomes invalid" do
      recipe = create(:recipe, :user_created, :with_ingredients)

      patch recipe_path(recipe), params: { recipe: { name: "" } }

      expect(response).to have_http_status(422)
    end
  end

  describe "PATCH /recipes/:id/react" do
    it "records a thumbs up" do
      recipe = create(:recipe)

      patch react_recipe_path(recipe), params: { reaction: "up" }

      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.reload).to be_reaction_up
    end

    it "clears a reaction" do
      recipe = create(:recipe, reaction: :up)

      patch react_recipe_path(recipe), params: { reaction: "none" }

      expect(recipe.reload).to be_reaction_none
    end

    it "rejects an unknown reaction" do
      recipe = create(:recipe)

      patch react_recipe_path(recipe), params: { reaction: "sideways" }

      expect(response).to redirect_to(recipe_path(recipe))
      expect(flash[:alert]).to eq("Invalid reaction.")
    end
  end

  describe "PATCH /recipes/:id/archive" do
    it "archives the recipe" do
      recipe = create(:recipe)

      patch archive_recipe_path(recipe)

      expect(response).to redirect_to(recipes_path)
      expect(recipe.reload).to be_status_archived
    end
  end

  describe "PATCH /recipes/:id/tired_of" do
    it "marks the recipe as tired of" do
      recipe = create(:recipe)

      patch tired_of_recipe_path(recipe)

      expect(response).to redirect_to(recipes_path)
      expect(recipe.reload).to be_status_tired_of
    end
  end

  describe "PATCH /recipes/:id/restore" do
    it "returns the recipe to active" do
      recipe = create(:recipe, :archived)

      patch restore_recipe_path(recipe)

      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.reload).to be_status_active
    end
  end

  describe "GET /recipes/grocery" do
    it "renders the grocery list" do
      recipe = create(:recipe, regular_meal: true)
      create(:recipe_ingredient, recipe: recipe, name: "Spinach", grocery_category: :produce)

      get grocery_recipes_path

      expect(response).to have_http_status(:ok)
    end

    it "renders with nothing planned" do
      get grocery_recipes_path

      expect(response).to have_http_status(:ok)
    end
  end
end
