# frozen_string_literal: true

# Run after deploy (or in CI) — aborts if core app logic would 500 in production.
# Usage: bin/rails runner script/production_smoke_test.rb

errors = []

begin
  Product.quick_log.load
rescue StandardError => e
  errors << "Product.quick_log: #{e.class} — #{e.message}"
end

begin
  log = DailyLog.includes(:workouts, :strength_sessions).new(logged_on: Date.current)
  log.calories_burned
rescue StandardError => e
  errors << "DailyLog#calories_burned: #{e.class} — #{e.message}"
end

begin
  Goal.current
rescue StandardError => e
  errors << "Goal.current: #{e.class} — #{e.message}"
end

if errors.any?
  warn "SMOKE TEST FAILED"
  errors.each { |err| warn "  • #{err}" }
  exit 1
end

puts "SMOKE OK"
