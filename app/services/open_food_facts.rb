# frozen_string_literal: true

require "net/http"
require "json"

# Look up packaged foods by barcode — strong coverage for French products.
class OpenFoodFacts
  API_BASE = "https://world.openfoodfacts.org/api/v2/product"

  class NotFound < StandardError; end

  def self.lookup(barcode)
    new(barcode).lookup
  end

  def initialize(barcode)
    @barcode = barcode.to_s.gsub(/\D/, "")
  end

  def lookup
    raise NotFound, "Invalid barcode" if @barcode.length < 8

    response = fetch_product
    raise NotFound, "Product not in Open Food Facts" unless response["status"] == 1

    parse(response["product"])
  end

  private

  def fetch_product
    uri = URI("#{API_BASE}/#{@barcode}.json?fields=code,product_name,product_name_fr,brands,nutriments,serving_size,serving_quantity")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 8

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "SilverHappiness/1.0 (personal nutrition tracker)"

    JSON.parse(http.request(request).body)
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise NotFound, "Could not reach Open Food Facts"
  end

  def parse(product)
    nutriments = product["nutriments"] || {}

    {
      barcode: product["code"] || @barcode,
      name: product["product_name_fr"].presence || product["product_name"].presence || "Unknown product",
      brand: product["brands"].to_s.split(",").first&.strip,
      calories_per_100g: energy_kcal(nutriments),
      protein_per_100g: nutriments["proteins_100g"],
      carbs_per_100g: nutriments["carbohydrates_100g"],
      fat_per_100g: nutriments["fat_100g"],
      default_serving_g: serving_g(product, nutriments),
      serving_label: product["serving_size"].presence,
      notes: "Imported from Open Food Facts (French/EU label data)"
    }.compact
  end

  def energy_kcal(nutriments)
    kcal = nutriments["energy-kcal_100g"]
    return kcal.round(1) if kcal.present?

    kj = nutriments["energy-kj_100g"] || nutriments["energy_100g"]
    return nil unless kj.present?

    (kj.to_f / 4.184).round(1)
  end

  def serving_g(product, nutriments)
    qty = product["serving_quantity"] || nutriments["serving_size"]
    qty.to_f.positive? ? qty.to_f : nil
  end
end
