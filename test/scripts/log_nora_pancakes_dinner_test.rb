# frozen_string_literal: true

require "test_helper"

class LogNoraPancakesDinnerTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  parallelize(workers: 1)

  test "log_nora_pancakes_dinner.rb has valid ruby syntax" do
    path = Rails.root.join("script/log_nora_pancakes_dinner.rb")
    assert_nothing_raised { RubyVM::InstructionSequence.compile_file(path.to_s) }
  end

  test "script logs pancake dinner with servings and extras" do
    setup_pancake_data!

    path = Rails.root.join("script/log_nora_pancakes_dinner.rb")
    env = {
      "LOGGED_ON" => "2026-08-08",
      "PANCAKES" => "7",
      "SKYR_TBSP" => "3",
      "STRAWBERRY_G" => "50"
    }

    assert_nothing_raised do
      env.each { |key, value| ENV[key] = value }
      load path
    end

    log = DailyLog.for_date(Date.parse("2026-08-08"))
    entry = log.meal_entries.find_by!("name LIKE ?", "%7 pancakes%")
    assert entry.calories.positive?
    assert entry.protein_g.positive?
    assert_includes entry.notes.to_s, "Skyr"
  ensure
    %w[LOGGED_ON PANCAKES SKYR_TBSP STRAWBERRY_G].each { |key| ENV.delete(key) }
  end

  private

  def setup_pancake_data!
    flour = Product.create!(name: "All-purpose flour", calories_per_100g: 364, protein_per_100g: 10)
    soja = Product.create!(name: "Soja sans sucre", calories_per_100g: 43, protein_per_100g: 3.9)
    oil = Product.create!(name: "Puget Huile d'olive vierge extra", calories_per_100g: 900, protein_per_100g: 0, fat_per_100g: 100)
    skyr = Product.create!(name: "Skyr vegan", calories_per_100g: 60, protein_per_100g: 7, default_serving_g: 15)
    berries = Product.create!(name: "Strawberries", calories_per_100g: 32, protein_per_100g: 0.7)

    template = MealTemplate.create!(name: "Nora Cooks vegan pancakes", slug: "noracooks-vegan-pancakes", meal_type: :dinner)
    template.meal_template_items.create!(product: flour, quantity_g: 23.5, label: "1 pancake batter")
    template.meal_template_items.create!(product: soja, quantity_g: 30, label: "soy milk")
    template.meal_template_items.create!(product: oil, quantity_g: 3.5, label: "oil")

    recipe = Recipe.create!(
      name: "Nora Cooks vegan pancakes",
      slug: "noracooks-vegan-pancakes",
      meal_type: :dinner,
      meal_template: template,
      serves: 1
    )
    recipe.recipe_ingredients.create!(name: "flour", grocery_category: :carbs, quantity_g: 23.5, product: flour, position: 0)
    recipe.sync_macros_from_ingredients!
  end
end
