# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Meal entries", type: :request do
  before { Goal.current }

  let(:log) { create(:daily_log) }

  describe "POST /daily_logs/:daily_log_id/meal_entries" do
    it "creates a custom entry from meal_entry params" do
      post daily_log_meal_entries_path(log), params: {
        meal_entry: { name: "Toast", meal_type: "breakfast", calories: 200, protein_g: 8 }
      }

      expect(response).to redirect_to(daily_log_path(log))
      expect(log.meal_entries.last.name).to eq("Toast")
    end

    it "creates an entry by copying a past meal" do
      tofu = create(:product, name: "Tofu", calories_per_100g: 145, protein_per_100g: 16)
      source_log = create(:daily_log, logged_on: Date.current - 2.days)
      source = source_log.meal_entries.create!(
        name: "Zucchini bowl", meal_type: :dinner,
        calories: 350, protein_g: 28, carbs_g: 20, fat_g: 12
      )
      source.record_items!([ { product_id: tofu.id, grams: 150 } ])
      source.save!

      expect {
        post daily_log_meal_entries_path(log), params: { source_meal_entry_id: source.id }
      }.to change(log.meal_entries, :count).by(1)

      entry = log.meal_entries.last
      expect(entry.name).to eq("Zucchini bowl")
      expect(entry.calories).to eq(350)
      expect(entry.items.map { |i| [ i.product_id, i.grams.to_f ] }).to eq([ [ tofu.id, 150.0 ] ])
    end

    it "creates an entry from a meal template" do
      template = create(:meal_template, :with_items)

      post daily_log_meal_entries_path(log), params: { meal_template_id: template.id }

      entry = log.meal_entries.last
      expect(entry.meal_template).to eq(template)
      expect(entry.calories).to eq(template.total_calories)
    end

    it "creates an entry from a quick-log product" do
      product = create(:quick_product, calories_per_100g: 100, default_serving_g: 150)

      post daily_log_meal_entries_path(log), params: { product_id: product.id }

      expect(log.meal_entries.last.calories).to eq(150)
    end

    it "logs water when the product is a beverage" do
      product = create(:beverage_product, water_volume_ml: 500)

      post daily_log_meal_entries_path(log), params: { product_id: product.id }

      expect(log.reload.water_ml).to eq(500)
      expect(log.meal_entries.last.water_logged_ml).to eq(500)
    end

    it "scales a recipe by servings and applies extras" do
      template = create(:meal_template, meal_type: :dinner)
      flour = create(:product, calories_per_100g: 364, protein_per_100g: 10)
      recipe = create(:recipe, meal_template: template, serves: 1)
      recipe.recipe_ingredients.create!(name: flour.name, product: flour, quantity_g: 25, grocery_category: :carbs)
      skyr = create(:product, name: "Skyr", default_serving_g: 15, calories_per_100g: 60)

      post daily_log_meal_entries_path(log), params: {
        meal_template_id: template.id,
        servings: 7,
        extras: { "0" => { product_id: skyr.id, quantity: 3, unit: "tbsp" } }
      }

      entry = log.meal_entries.last
      per_serving = recipe.reload.nutrition_per_serving[:calories]
      expect(entry.calories).to eq((per_serving * 7).round + skyr.nutrition_for(45)[:calories])
      expect(entry.notes).to include("Skyr")
    end

    it "redirects with an alert when the entry is invalid" do
      post daily_log_meal_entries_path(log), params: { meal_entry: { name: "", calories: 100 } }

      expect(response).to redirect_to(daily_log_path(log))
      expect(flash[:alert]).to be_present
    end

    it "returns 404 for an unknown daily log" do
      post daily_log_meal_entries_path(daily_log_id: 999_999), params: {
        meal_entry: { name: "Toast", calories: 100, protein_g: 1 }
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /daily_logs/:daily_log_id/meal_entries/:id/edit" do
    it "renders the plain edit form" do
      entry = create(:meal_entry, daily_log: log)

      get edit_daily_log_meal_entry_path(log, entry)

      expect(response).to have_http_status(:ok)
    end

    it "renders the recipe form when the entry came from a recipe template" do
      template = create(:meal_template)
      create(:recipe, meal_template: template)
      entry = create(:meal_entry, daily_log: log, meal_template: template)

      get edit_daily_log_meal_entry_path(log, entry)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /daily_logs/:daily_log_id/meal_entries/:id" do
    it "updates the entry" do
      entry = create(:meal_entry, daily_log: log)

      patch daily_log_meal_entry_path(log, entry), params: {
        meal_entry: { name: "Updated", calories: 555, protein_g: 30 }
      }

      expect(response).to redirect_to(daily_log_path(log))
      expect(entry.reload.name).to eq("Updated")
      expect(entry.calories).to eq(555)
    end

    it "re-renders with 422 when invalid" do
      entry = create(:meal_entry, daily_log: log)

      patch daily_log_meal_entry_path(log, entry), params: { meal_entry: { name: "" } }

      expect(response).to have_http_status(422)
    end
  end

  describe "DELETE /daily_logs/:daily_log_id/meal_entries/:id" do
    it "removes the entry" do
      entry = create(:meal_entry, daily_log: log)

      delete daily_log_meal_entry_path(log, entry)

      expect(response).to redirect_to(daily_log_path(log))
      expect(MealEntry.exists?(entry.id)).to be false
    end
  end

  describe "POST /daily_logs/:daily_log_id/meal_entries/:id/log_water" do
    it "logs the suggested water for the meal" do
      entry = create(:meal_entry, daily_log: log, water_suggestion_ml: 250)

      post log_water_daily_log_meal_entry_path(log, entry)

      expect(response).to redirect_to(daily_log_path(log))
      expect(log.reload.water_ml).to eq(250)
    end

    it "does not double-log water for the same meal" do
      entry = create(:meal_entry, daily_log: log, water_suggestion_ml: 250)
      post log_water_daily_log_meal_entry_path(log, entry)
      post log_water_daily_log_meal_entry_path(log, entry)

      expect(log.reload.water_ml).to eq(250)
    end
  end
end
