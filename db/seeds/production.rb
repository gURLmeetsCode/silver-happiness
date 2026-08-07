# frozen_string_literal: true

# Production: workout plans + your real baseline (products, templates, Aug 6–7 logs).
# Re-running db:seed updates baseline records; it does not wipe data you add later.

load Rails.root.join("db/seeds/structure.rb")
load Rails.root.join("db/seeds/baseline_data.rb")
load Rails.root.join("db/seeds/recipes.rb")

puts "Production seed complete."
