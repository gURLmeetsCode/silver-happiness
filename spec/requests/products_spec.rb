# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products", type: :request do
  describe "GET /products/new" do
    it "renders name search and barcode lookup without a camera scanner" do
      get new_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("barcode-lookup")
      expect(response.body).to include("Search by name")
      expect(response.body).to include("/products/search")
      expect(response.body).not_to match(/startScan|Open scanner|barcode-scanner/)
    end
  end

  describe "POST /products" do
    it "saves a product and returns home" do
      expect {
        post products_path, params: {
          product: { name: "Fresh Tofu Block", calories_per_100g: 145, protein_per_100g: 14 }
        }
      }.to change(Product, :count).by(1)

      expect(response).to redirect_to(root_path)
    end

    it "updates an existing product instead of creating a duplicate name" do
      existing = create(:product, name: "Tofu", calories_per_100g: 100, protein_per_100g: 10)

      expect {
        post products_path, params: {
          product: { name: "tofu", calories_per_100g: 145, protein_per_100g: 14 }
        }
      }.not_to change(Product, :count)

      expect(response).to redirect_to(root_path)
      expect(existing.reload.calories_per_100g).to eq(145)
      expect(flash[:notice]).to include("already in your products")
    end

    it "updates an existing product matched by barcode" do
      existing = create(:product, name: "Old Name", barcode: "3168930173199", calories_per_100g: 100, protein_per_100g: 5)

      expect {
        post products_path, params: {
          product: {
            name: "Sweet Chilli Pepper Tortillas",
            barcode: "3168930173199",
            calories_per_100g: 280,
            protein_per_100g: 8
          }
        }
      }.not_to change(Product, :count)

      expect(existing.reload.name).to eq("Sweet Chilli Pepper Tortillas")
      expect(existing.calories_per_100g).to eq(280)
    end

    it "honours return_to" do
      log = create(:daily_log)

      post products_path, params: {
        product: { name: "Return Tofu", calories_per_100g: 145, protein_per_100g: 14 },
        return_to: daily_log_path(log)
      }

      expect(response).to redirect_to(daily_log_path(log))
    end

    it "ignores an off-site return_to" do
      post products_path, params: {
        product: { name: "Offsite Tofu", calories_per_100g: 145, protein_per_100g: 14 },
        return_to: "https://evil.example.com"
      }

      expect(response).to redirect_to(root_path)
    end

    it "ignores a protocol-relative return_to" do
      post products_path, params: {
        product: { name: "Protocol Tofu", calories_per_100g: 145, protein_per_100g: 14 },
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

  describe "POST /products/search" do
    it "returns matching products as JSON" do
      allow(OpenFoodFacts).to receive(:search).with("sojasun").and_return([
        { name: "Yaourt nature", brand: "Sojasun", calories_per_100g: 43 }
      ])

      post search_products_path, params: { q: "sojasun" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["products"].length).to eq(1)
      expect(json["products"].first["name"]).to eq("Yaourt nature")
    end

    it "returns 404 when nothing matches" do
      allow(OpenFoodFacts).to receive(:search).and_raise(OpenFoodFacts::NotFound, "No products found")

      post search_products_path, params: { q: "zzzznotaproduct" }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["products"]).to eq([])
    end
  end
end
