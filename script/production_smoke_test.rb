# frozen_string_literal: true

# Run after deploy (or in CI) — aborts if core app logic would 500 in production.
# Usage: bin/rails runner script/production_smoke_test.rb

require "action_dispatch/testing/integration"

errors = []

def record_error(errors, label)
  yield
rescue StandardError => e
  errors << "#{label}: #{e.class} — #{e.message}"
end

record_error(errors, "Product.order") { Product.order(:name).limit(5).load }

record_error(errors, "DailyLog#calories_burned") do
  log = DailyLog.includes(:workouts, :strength_sessions).new(logged_on: Date.current)
  log.calories_burned
end

record_error(errors, "Goal.current") { Goal.current }

session = ActionDispatch::Integration::Session.new(Rails.application)
session.host! "127.0.0.1"
https = {
  "X-Forwarded-Proto" => "https",
  "User-Agent" => "Mozilla/5.0 (compatible; SilverHappinessSmokeTest/1.0) Chrome/120.0.0.0"
}

record_error(errors, "GET /") do
  session.get("/", headers: https)
  errors << "GET / returned HTTP #{session.response.status}" unless session.response.successful?
end

record_error(errors, "recipe meal form partial") do
  recipe = Recipe.includes(:meal_template, recipe_ingredients: :product)
    .find_by(slug: "chipotle-yogurt-salad") ||
    Recipe.includes(:meal_template, recipe_ingredients: :product).joins(:meal_template).first
  next unless recipe

  RecipeMealFormBuilder.new(recipe)

  ApplicationController.render(
    partial: "recipes/recipe_meal_form",
    locals: {
      recipe: recipe,
      daily_log: DailyLog.today,
      products: Product.order(:name),
      form_url: "/daily_logs/#{DailyLog.today.id}/meal_entries",
      form_method: :post
    }
  )
end

record_error(errors, "GET chipotle tofu wrap") do
  recipe = Recipe.joins(:meal_template).find_by(slug: "chipotle-yogurt-salad") ||
    Recipe.joins(:meal_template).first
  if recipe.nil?
    errors << "No recipe with meal template in database"
    next
  end

  session.get("/recipes/#{recipe.id}", headers: https)
  unless session.response.successful?
    errors << "GET /recipes/#{recipe.id} (#{recipe.slug}) returned HTTP #{session.response.status}"
  end
end

# A broken image only shows up in the browser, never in the logs, so check that
# a stored photo can still be located and addressed.
record_error(errors, "photo display") do
  photo = ProgressPhoto.with_attached_image.last || OutfitPhoto.with_attached_image.last
  next unless photo&.image&.attached?

  errors << "photo blob missing from storage" unless photo.image.blob.service.exist?(photo.image.blob.key)
  Rails.application.routes.url_helpers.rails_blob_path(photo.image, only_path: true)
end

record_error(errors, "GET /metrics") do
  session.get("/metrics", headers: https)
  errors << "GET /metrics returned HTTP #{session.response.status}" unless session.response.successful?
end

record_error(errors, "GET /metrics/export PDF") do
  session.get("/metrics/export", headers: https)
  unless session.response.successful?
    errors << "GET /metrics/export returned HTTP #{session.response.status}"
    next
  end
  unless session.response.body.to_s.start_with?("%PDF")
    errors << "GET /metrics/export did not return a PDF"
  end
end

# Uploads are downscaled with MiniMagick, which needs the ImageMagick binary.
record_error(errors, "ImageMagick available") do
  MiniMagick.cli_version
rescue StandardError => e
  errors << "ImageMagick not usable: #{e.message}"
end

if errors.any?
  warn "SMOKE TEST FAILED"
  errors.each { |err| warn "  • #{err}" }
  exit 1
end

puts "SMOKE OK"
