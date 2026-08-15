# frozen_string_literal: true

# Compact quick-add from what you actually ate in the last week — filtered to
# the meal types you're most likely logging *right now* (Paris local time).
# Prefers recipe-linked meals; skips lone ingredients already inside a build.
class RecentMealShortcuts
  DAYS = 7
  LIMIT = 5

  # Local hour (Europe/Paris) → meal types worth offering.
  SLOTS = [
    { hours: 5..10,  types: %w[breakfast],            label: "Breakfast" },
    { hours: 10..11, types: %w[breakfast snack lunch], label: "Late morning" },
    { hours: 11..15, types: %w[lunch],                 label: "Lunch" },
    { hours: 15..17, types: %w[snack lunch],           label: "Afternoon" },
    { hours: 17..21, types: %w[dinner snack],          label: "Dinner" },
    { hours: 21..24, types: %w[snack dinner],          label: "Evening" },
    { hours: 0..5,   types: %w[snack dinner],          label: "Late night" }
  ].freeze

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

  Result = Struct.new(:shortcuts, :slot_label, :meal_types, keyword_init: true)

  def self.call(as_of: Date.current, at: Time.zone.now, days: DAYS, limit: LIMIT)
    new(as_of: as_of, at: at, days: days, limit: limit).call
  end

  def initialize(as_of:, at:, days:, limit:)
    @as_of = as_of
    @at = at.in_time_zone
    @days = days
    @limit = limit
  end

  def call
    slot = current_slot
    types = slot[:types]
    entries = recent_entries.to_a
    covered_by_builds = product_ids_in_built_meals(entries)

    # Only time-filter when logging *today*. Catching up on another day shows all.
    candidates = if @as_of == @at.to_date
      entries.select { |entry| types.include?(entry.meal_type) }
    else
      entries
    end

    seen = {}
    shortcuts = []

    ranked(candidates).each do |entry|
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

    Result.new(
      shortcuts: shortcuts,
      slot_label: (@as_of == @at.to_date) ? slot[:label] : "This week",
      meal_types: types
    )
  end

  private

  def current_slot
    hour = @at.hour
    SLOTS.find { |slot| slot[:hours].cover?(hour) } || SLOTS.first
  end

  def ranked(entries)
    # Recipe-backed first (editable portions), then newest.
    entries.sort_by do |entry|
      recipe_rank = entry.meal_template&.recipe ? 0 : 1
      [ recipe_rank, -entry.daily_log.logged_on.to_time.to_i, -entry.created_at.to_i ]
    end
  end

  def recent_entries
    from = @as_of - @days.days
    MealEntry
      .joins(:daily_log)
      .includes(:items, :daily_log, meal_template: :recipe)
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
