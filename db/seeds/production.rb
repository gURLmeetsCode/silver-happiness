# frozen_string_literal: true

# Reference data only: workout plans, products, meal templates, and recipes.
#
# Safe to re-run against a live database. Seeding never edits or deletes a day
# you logged, a meal you entered, a photo you uploaded, or a recipe you wrote —
# the Aug 6–7 2026 sample days are skipped entirely once those days exist.
# See spec/seeds/seed_preserves_user_data_spec.rb, which asserts exactly that.
#
# Note that `bin/deploy` does NOT run this; deploys only run migrations.

load Rails.root.join("db/seeds/structure.rb")
load Rails.root.join("db/seeds/baseline_data.rb")
load Rails.root.join("db/seeds/recipes.rb")

puts "Production seed complete."
