# frozen_string_literal: true

require "rails_helper"

RSpec.describe "script/log_nora_pancakes_dinner.rb" do
  let(:script) { Rails.root.join("script/log_nora_pancakes_dinner.rb") }

  it "is syntactically valid Ruby" do
    expect { RubyVM::InstructionSequence.compile_file(script.to_s) }.not_to raise_error
  end

  context "with the pancake recipe seeded" do
    before do
      flour = create(:product, name: "All-purpose flour", calories_per_100g: 364, protein_per_100g: 10)
      create(:product, name: "Skyr vegan", calories_per_100g: 60, protein_per_100g: 7, default_serving_g: 15)
      create(:product, name: "Strawberries", calories_per_100g: 32, protein_per_100g: 0.7)

      template = create(:meal_template, name: "Nora Cooks vegan pancakes", slug: "noracooks-vegan-pancakes", meal_type: :dinner)
      template.meal_template_items.create!(product: flour, quantity_g: 23.5, label: "1 pancake batter")

      recipe = create(:recipe, name: "Nora Cooks vegan pancakes", slug: "noracooks-vegan-pancakes", meal_type: :dinner, meal_template: template, serves: 1)
      recipe.recipe_ingredients.create!(name: "flour", grocery_category: :carbs, quantity_g: 23.5, product: flour, position: 0)
      recipe.sync_macros_from_ingredients!
    end

    after do
      %w[LOGGED_ON PANCAKES SKYR_TBSP STRAWBERRY_G].each { |key| ENV.delete(key) }
    end

    it "logs the dinner with servings and extras" do
      ENV["LOGGED_ON"] = "2026-08-08"
      ENV["PANCAKES"] = "7"
      ENV["SKYR_TBSP"] = "3"
      ENV["STRAWBERRY_G"] = "50"

      expect { load script }.to output(/7 pancakes/).to_stdout

      log = DailyLog.find_by!(logged_on: Date.parse("2026-08-08"))
      entry = log.meal_entries.sole
      expect(entry.calories).to be_positive
      expect(entry.notes).to include("Skyr vegan")
      expect(entry.notes).to include("Strawberries")
    end

    it "defaults to yesterday when LOGGED_ON is not set" do
      expect { load script }.to output.to_stdout

      expect(DailyLog.find_by(logged_on: Date.yesterday)).to be_present
    end
  end
end
