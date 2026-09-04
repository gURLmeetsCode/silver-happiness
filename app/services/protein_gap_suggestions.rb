# frozen_string_literal: true

# When protein is still short of the daily min, surface a few familiar high-protein
# picks (staples + active recipes) so logging can close the gap without hunting.
class ProteinGapSuggestions
  STAPLE_PATTERN = /tofu|skyr|protein|tempeh|seitan|edamame|lentil|chickpea|yaourt|sojasun|hummus|houmous|bean|tvp/i
  MIN_PRODUCT_PROTEIN_G = 8
  MIN_RECIPE_PROTEIN_G = 15

  Pick = Data.define(:kind, :label, :protein_g, :detail, :record)
  Result = Data.define(:grams_left, :met_min, :picks)

  def self.call(daily_log:, goal: Goal.current, limit: 3)
    new(daily_log, goal, limit).call
  end

  def initialize(daily_log, goal, limit)
    @daily_log = daily_log
    @goal = goal
    @limit = limit
  end

  def call
    left = @daily_log.protein_to_min_g(@goal)
    return Result.new(grams_left: [ left, 0 ].max, met_min: left <= 0, picks: []) if left <= 0

    picks = (product_picks + recipe_picks)
      .uniq { |pick| [ pick.kind, pick.record.id ] }
      .sort_by { |pick| [ -staple_bonus(pick), -pick.protein_g, pick.label ] }
      .first(@limit)

    Result.new(grams_left: left, met_min: false, picks: picks)
  end

  private

  def product_picks
    Product.where("protein_per_100g >= ?", 8)
      .order(Arel.sql("CASE WHEN quick_log THEN 0 ELSE 1 END"), protein_per_100g: :desc, name: :asc)
      .limit(40)
      .filter_map do |product|
      next if product.beverage?

      grams = product.default_quantity_g.to_f
      next unless grams.positive?

      protein = product.nutrition_for(grams)[:protein].to_f
      next if protein < MIN_PRODUCT_PROTEIN_G

      Pick.new(
        kind: :product,
        label: product.name,
        protein_g: protein.round(0),
        detail: product.serving_label.presence || "#{grams.to_i} g",
        record: product
      )
    end
  end

  def recipe_picks
    Recipe.status_active.includes(:recipe_ingredients).filter_map do |recipe|
      protein = recipe.nutrition_per_serving[:protein].to_f
      protein = recipe.protein_g.to_f if protein <= 0 && recipe.protein_g.present?
      next if protein < MIN_RECIPE_PROTEIN_G

      Pick.new(
        kind: :recipe,
        label: recipe.name,
        protein_g: protein.round(0),
        detail: "1 serving",
        record: recipe
      )
    end
  end

  def staple_bonus(pick)
    name = pick.record.name.to_s
    return 2 if pick.kind == :product && pick.record.try(:quick_log?)
    return 1 if name.match?(STAPLE_PATTERN)

    0
  end
end
