# frozen_string_literal: true

# Meals you actually ate lately — the only shortcuts worth a one-tap re-log.
# Looks back a week, keeps one row per recipe/template (or meal name), newest first.
# Skips a lone ingredient (e.g. "Psyllium husk morning") when you already logged
# a built meal that includes that same product (e.g. fiber greens + psyllium).
class RecentMealShortcuts
  DAYS = 7
  LIMIT = 10

  Shortcut = Struct.new(
    :name, :meal_type, :calories, :protein_g, :source_entry, :recipe, :meal_template,
    keyword_init: true
  ) do
    def recipe?
      recipe.present?
    end

    def label
      parts = [ name, "#{calories} kcal" ]
      parts << "#{protein_g} g protein" if protein_g.to_f.positive?
      parts.join(" · ")
    end
  end

  def self.call(as_of: Date.current, days: DAYS, limit: LIMIT)
    new(as_of: as_of, days: days, limit: limit).call
  end

  def initialize(as_of:, days:, limit:)
    @as_of = as_of
    @days = days
    @limit = limit
  end

  def call
    entries = recent_entries.to_a
    covered_by_builds = product_ids_in_built_meals(entries)
    seen = {}
    shortcuts = []

    entries.each do |entry|
      next if redundant_single_ingredient?(entry, covered_by_builds)

      key = dedupe_key(entry)
      next if seen[key]

      seen[key] = true
      template = entry.meal_template
      shortcuts << Shortcut.new(
        name: entry.name,
        meal_type: entry.meal_type,
        calories: entry.calories,
        protein_g: entry.protein_g,
        source_entry: entry,
        meal_template: template,
        recipe: template&.recipe
      )
      break if shortcuts.size >= @limit
    end

    shortcuts
  end

  private

  def recent_entries
    from = @as_of - @days.days
    MealEntry
      .joins(:daily_log)
      .includes(:items, meal_template: :recipe)
      .where(daily_logs: { logged_on: from..@as_of })
      .where.not(meal_type: :beverage)
      .order("daily_logs.logged_on DESC, meal_entries.created_at DESC")
  end

  def product_ids_in_built_meals(entries)
    entries
      .select { |entry| entry.items.size >= 2 }
      .flat_map { |entry| entry.items.map(&:product_id) }
      .to_set
  end

  def redundant_single_ingredient?(entry, covered_product_ids)
    return false unless entry.items.size == 1

    covered_product_ids.include?(entry.items.first.product_id)
  end

  def dedupe_key(entry)
    if entry.meal_template_id.present?
      "template:#{entry.meal_template_id}"
    else
      "name:#{entry.meal_type}:#{entry.name.to_s.strip.downcase}"
    end
  end
end
