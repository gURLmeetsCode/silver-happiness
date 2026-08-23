# frozen_string_literal: true

require "net/http"
require "json"

# Look up packaged foods by barcode or name — strong coverage for French products.
class OpenFoodFacts
  PRODUCT_API_BASES = [
    "https://world.openfoodfacts.org/api/v2/product",
    "https://fr.openfoodfacts.org/api/v2/product"
  ].freeze

  SEARCH_API_BASES = [
    "https://fr.openfoodfacts.org/cgi/search.pl",
    "https://world.openfoodfacts.org/cgi/search.pl"
  ].freeze

  SEARCH_FIELDS = %w[
    code product_name product_name_fr brands nutriments serving_size serving_quantity
  ].join(",").freeze

  class NotFound < StandardError; end

  def self.lookup(barcode)
    new(barcode: barcode).lookup
  end

  def self.search(query, limit: 10)
    new(query: query, limit: limit).search
  end

  def initialize(barcode: nil, query: nil, limit: 10)
    @barcode = barcode.to_s.gsub(/\D/, "")
    @query = query.to_s.strip
    @limit = [[ limit.to_i, 1 ].max, 20].min
  end

  def lookup
    raise NotFound, "Invalid barcode" if @barcode.length < 8

    response = fetch_product
    raise NotFound, "Product not in Open Food Facts" unless response["status"] == 1

    parse(response["product"])
  end

  def search
    raise NotFound, "Enter at least 2 characters" if @query.length < 2

    products = fetch_search
    raise NotFound, "No products found" if products.blank?

    products.filter_map { |product| parse(product) }
  end

  private

  def fetch_product
    last_error = nil

    PRODUCT_API_BASES.each do |base|
      uri = URI("#{base}/#{@barcode}.json?fields=#{SEARCH_FIELDS}")
      response = http_get_json(uri)
      return response if response["status"] == 1
    rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      last_error = e
      next
    end

    raise NotFound, "Could not reach Open Food Facts" if last_error

    { "status" => 0 }
  end

  def fetch_search
    last_error = nil

    SEARCH_API_BASES.each do |base|
      uri = URI(base)
      uri.query = URI.encode_www_form(
        search_terms: @query,
        search_simple: 1,
        action: "process",
        json: 1,
        page_size: @limit,
        fields: SEARCH_FIELDS
      )
      response = http_get_json(uri)
      products = Array(response["products"])
      return products if products.any?
    rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      last_error = e
      next
    end

    raise NotFound, "Could not reach Open Food Facts" if last_error

    []
  end

  def http_get_json(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "SilverHappiness/1.0 (personal nutrition tracker)"

    JSON.parse(http.request(request).body)
  end

  def parse(product)
    return nil if product.blank?

    nutriments = product["nutriments"] || {}
    name = product["product_name_fr"].presence || product["product_name"].presence
    return nil if name.blank?

    {
      barcode: product["code"].presence || @barcode.presence,
      name: name,
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
