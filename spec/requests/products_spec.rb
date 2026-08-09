# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products", type: :request do
  describe "GET /products/new" do
    it "renders the manual barcode form without a camera scanner" do
      get new_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("barcode-lookup")
      expect(response.body).not_to match(/startScan|Open scanner|barcode-scanner/)
    end
  end

  describe "POST /products" do
    it "saves a product and returns home" do
      expect {
        post products_path, params: {
          product: { name: "Tofu", calories_per_100g: 145, protein_per_100g: 14 }
        }
      }.to change(Product, :count).by(1)

      expect(response).to redirect_to(root_path)
    end

    it "honours return_to" do
      log = create(:daily_log)

      post products_path, params: {
        product: { name: "Tofu", calories_per_100g: 145, protein_per_100g: 14 },
        return_to: daily_log_path(log)
      }

      expect(response).to redirect_to(daily_log_path(log))
    end

    it "ignores an off-site return_to" do
      post products_path, params: {
        product: { name: "Tofu", calories_per_100g: 145, protein_per_100g: 14 },
        return_to: "https://evil.example.com"
      }

      expect(response).to redirect_to(root_path)
    end

    it "ignores a protocol-relative return_to" do
      post products_path, params: {
        product: { name: "Tofu", calories_per_100g: 145, protein_per_100g: 14 },
        return_to: "//evil.example.com"
      }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "the Cancel link on the new product form" do
    it "points at return_to when it is a local path" do
      log = create(:daily_log)

      get new_product_path, params: { return_to: daily_log_path(log) }

      expect(response.body).to include("href=\"#{daily_log_path(log)}\"")
    end

    it "falls back home for an off-site return_to" do
      get new_product_path, params: { return_to: "https://evil.example.com" }

      expect(response.body).not_to include("evil.example.com")
    end

    it "re-renders with 422 when the name is missing" do
      post products_path, params: { product: { calories_per_100g: 100, protein_per_100g: 5 } }

      expect(response).to have_http_status(422)
    end

    it "re-renders with 422 when a quick-log product has no serving size" do
      post products_path, params: {
        product: { name: "Snack", calories_per_100g: 100, protein_per_100g: 5, quick_log: "1" }
      }

      expect(response).to have_http_status(422)
    end

    it "rejects a water volume on a non-beverage" do
      post products_path, params: {
        product: {
          name: "Crisps", calories_per_100g: 500, protein_per_100g: 5,
          beverage: "0", water_volume_ml: 500
        }
      }

      expect(response).to have_http_status(422)
    end
  end

  describe "POST /products/lookup_barcode" do
    it "returns the product nutrition as JSON" do
      payload = {
        barcode: "3259011034000",
        name: "Test Product",
        brand: "Test Brand",
        calories_per_100g: 42,
        protein_per_100g: 3.5,
        carbs_per_100g: 5.1,
        fat_per_100g: 1.2
      }
      allow(OpenFoodFacts).to receive(:lookup).with("3259011034000").and_return(payload)

      post lookup_barcode_products_path, params: { barcode: "3259011034000" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["name"]).to eq("Test Product")
      expect(json["calories_per_100g"]).to eq(42)
    end

    it "returns 404 when the barcode is unknown" do
      allow(OpenFoodFacts).to receive(:lookup).and_raise(OpenFoodFacts::NotFound, "No product found")

      post lookup_barcode_products_path, params: { barcode: "0000000000000" }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to be_present
    end

    it "is also reachable over GET" do
      allow(OpenFoodFacts).to receive(:lookup).and_return({ name: "Test" })

      get lookup_barcode_products_path, params: { barcode: "123" }, as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
