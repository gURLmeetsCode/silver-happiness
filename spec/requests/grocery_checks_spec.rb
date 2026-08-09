# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Grocery checks", type: :request do
  describe "POST /grocery_checks/toggle" do
    it "checks an item" do
      post toggle_grocery_checks_path, params: { item_key: "batch:veg" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["checked"]).to be true
    end

    it "unchecks on a second toggle" do
      post toggle_grocery_checks_path, params: { item_key: "batch:veg" }, as: :json
      post toggle_grocery_checks_path, params: { item_key: "batch:veg" }, as: :json

      expect(response.parsed_body["checked"]).to be false
    end

    it "returns 400 when item_key is missing" do
      post toggle_grocery_checks_path, params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /grocery_checks/reset" do
    it "clears checks for the current period" do
      period = ShoppingPeriod.current
      create(:grocery_check, shopping_period: period, item_key: "batch:veg")

      delete reset_grocery_checks_path

      expect(response).to redirect_to(grocery_recipes_path)
      expect(GroceryCheck.for_period(period)).to be_empty
    end
  end
end
