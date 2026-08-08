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

record_error(errors, "Product.quick_log") { Product.quick_log.load }

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
  recipe = Recipe.includes(:meal_template, recipe_ingredients: :product).joins(:meal_template).first
  next unless recipe

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

record_error(errors, "GET /recipes/:id") do
  recipe = Recipe.joins(:meal_template).first
  next unless recipe

  session.get("/recipes/#{recipe.id}", headers: https)
  unless session.response.successful?
    errors << "GET /recipes/#{recipe.id} returned HTTP #{session.response.status}"
  end
end

if errors.any?
  warn "SMOKE TEST FAILED"
  errors.each { |err| warn "  • #{err}" }
  exit 1
end

puts "SMOKE OK"
