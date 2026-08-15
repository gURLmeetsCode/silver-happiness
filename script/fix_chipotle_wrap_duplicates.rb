# frozen_string_literal: true

# Deduplicate Chipotle tofu wrap recipes: keep one active, archive the rest.
#
#   bin/rails runner script/fix_chipotle_wrap_duplicates.rb

def normalize(name)
  name.to_s.downcase.gsub(/[^a-z0-9]+/, "")
end

matches = Recipe.all.select do |recipe|
  key = normalize(recipe.name)
  key.include?("chipotletofuwrap") ||
    key.include?("chipotleyogurtsalad") ||
    recipe.slug.to_s.include?("chipotle")
end

if matches.empty?
  puts "No Chipotle wrap recipes found."
  exit
end

puts "Found #{matches.size}:"
matches.each do |recipe|
  puts "  id=#{recipe.id} slug=#{recipe.slug} status=#{recipe.status} " \
       "user_created=#{recipe.user_created} name=#{recipe.name.inspect}"
end

keeper = matches.find { |r| r.slug == "chipotle-yogurt-salad" } ||
  matches.find { |r| r.meal_template_id.present? && !r.user_created? } ||
  matches.min_by(&:id)

keeper.update!(status: :active, regular_meal: true)
puts "==> Keeper active: id=#{keeper.id} slug=#{keeper.slug}"

matches.each do |recipe|
  next if recipe.id == keeper.id

  # Point meal entries that used the duplicate's template at the keeper's template
  # when the duplicate had its own template.
  if recipe.meal_template_id.present? &&
      keeper.meal_template_id.present? &&
      recipe.meal_template_id != keeper.meal_template_id
    MealEntry.where(meal_template_id: recipe.meal_template_id)
      .update_all(meal_template_id: keeper.meal_template_id)
  end

  recipe.update!(status: :archived, regular_meal: false)
  puts "  archived duplicate id=#{recipe.id} slug=#{recipe.slug}"
end

puts "==> Done. Active Chipotle wraps: " \
     "#{Recipe.status_active.select { |r| normalize(r.name).include?("chipotle") }.map(&:slug).join(", ")}"
