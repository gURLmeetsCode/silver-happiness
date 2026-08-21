# frozen_string_literal: true

# Compact quick-add from what you actually eat often — filtered to the meal
# types you're most likely logging *right now* (Paris local time).
# Uses the latest version of each usual meal so a small tweak becomes next time's default.
class RecentMealShortcuts
  DAYS = 21
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
    :name, :meal_type, :calories, :protein_g, :source_entry, :recipe, :meal_template, :times_eaten,
    keyword_init: true
  ) do
    def recipe?
      recipe.present?
    end

    def label
      parts = [ name ]
      parts << "#{times_eaten}× lately" if times_eaten.to_i > 1
      parts << "#{calories} kcal"
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

    shortcuts = grouped_usuals(candidates, covered_by_builds).first(@limit).map do |group|
      entry = group[:latest]
      template = entry.meal_template
      recipe = template&.recipe
      recipe = nil if recipe&.status_archived?

      Shortcut.new(
        name: entry.name,
        meal_type: entry.meal_type,
        calories: entry.calories,
        protein_g: entry.protein_g,
        source_entry: entry,
        meal_template: template,
        recipe: recipe,
        times_eaten: group[:count]
      )
    end

    Result.new(
      shortcuts: shortcuts,
      slot_label: (@as_of == @at.to_date) ? slot[:label] : "Usual meals",
      meal_types: types
    )
  end

  private

  def current_slot
    hour = @at.hour
    SLOTS.find { |slot| slot[:hours].cover?(hour) } || SLOTS.first
  end

  def grouped_usuals(entries, covered_product_ids)
    groups = {}

    entries.each do |entry|
      next if redundant_single_ingredient?(entry, covered_product_ids)

      key = dedupe_key(entry)
      if (group = groups[key])
        group[:count] += 1
        group[:latest] = entry if newer?(entry, group[:latest])
      else
        group = groups[key] = { latest: entry, count: 1, recipe_rank: 1 }
      end

      recipe = entry.meal_template&.recipe
      if recipe.present? && !recipe.status_archived?
        group[:recipe_rank] = 0
      end
    end

    groups.values.sort_by do |group|
      logged_on = group[:latest].daily_log.logged_on
      [ -group[:count], group[:recipe_rank], -logged_on.to_time.to_i, -group[:latest].created_at.to_i ]
    end
  end

  def newer?(entry, other)
    return true if entry.daily_log.logged_on > other.daily_log.logged_on
    return false if entry.daily_log.logged_on < other.daily_log.logged_on

    entry.created_at > other.created_at
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
