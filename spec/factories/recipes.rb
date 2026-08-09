# frozen_string_literal: true

FactoryBot.define do
  factory :recipe do
    sequence(:name) { |n| "Recipe #{n}" }
    sequence(:slug) { |n| "recipe-#{n}" }
    meal_type { :dinner }
    serves { 1 }
    calories { 400 }
    protein_g { 25 }
    description { "A test recipe." }
    steps { "1. Cook it.\n2. Eat it." }

    trait :user_created do
      user_created { true }
    end

    trait :archived do
      status { :archived }
    end

    trait :tired_of do
      status { :tired_of }
    end

    # Built before save so it satisfies the user_created ingredient validation.
    trait :with_ingredients do
      after(:build) do |recipe|
        recipe.recipe_ingredients << build(:recipe_ingredient, recipe: recipe, position: 0)
      end
    end

    trait :with_template do
      meal_template
    end
  end

  factory :recipe_ingredient do
    recipe
    sequence(:name) { |n| "Ingredient #{n}" }
    amount { "100 g" }
    grocery_category { :produce }

    trait :tracked do
      product
      quantity_g { 100 }
    end
  end
end
