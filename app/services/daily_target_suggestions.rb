# frozen_string_literal: true

# Tips when today's eaten macros miss the calorie or protein targets. Calorie
# tips name a real item you logged and the exact amount that would bring the day
# closer; they are never invented from the meal's name.
class DailyTargetSuggestions
  Suggestion = Data.define(:message, :savings_kcal, :adds_protein_g)

  CALORIE_THRESHOLD = 150
  PROTEIN_THRESHOLD = 5

  # Leave the densest protein alone — cutting tofu to save calories is rarely
  # what you meant. Prefer oils and dressings first.
  PROTEIN_SHARE_FLOOR = 0.25
  MIN_SAVINGS_KCAL = 20
  # Never suggest cutting more than half of what was eaten; "skip it" is its own
  # tip when the whole item is small enough to matter.
  MAX_CUT_FRACTION = 0.5

  def initialize(daily_log, goal: Goal.current)
    @log = daily_log
    @goal = goal
  end

  def relevant?
    headline.present?
  end

  def headline
    if calorie_overshoot >= CALORIE_THRESHOLD
      "You're #{calorie_overshoot.round} kcal over today's ~#{@log.calorie_target} kcal target."
    elsif protein_shortfall >= PROTEIN_THRESHOLD
      "You're #{protein_shortfall.round(1)} g below your #{@goal.protein_min_g} g protein minimum."
    end
  end

  def subheadline
    return "Things that would close the protein gap:" if protein_shortfall >= PROTEIN_THRESHOLD && calorie_overshoot < CALORIE_THRESHOLD

    "What you logged, trimmed:" if calorie_overshoot >= CALORIE_THRESHOLD
  end

  def suggestions
    @suggestions ||= (calorie_tips + protein_tips).uniq(&:message).first(5)
  end

  private

  def calorie_overshoot
    [ @log.total_calories - @log.calorie_target, 0 ].max
  end

  def protein_shortfall
    [ @goal.protein_min_g - @log.total_protein, 0 ].max
  end

  def calorie_tips
    return [] unless calorie_overshoot >= CALORIE_THRESHOLD

    tips = reducible_items.filter_map { |item| tip_for(item) }
    tips = tips.sort_by { |tip| -tip.savings_kcal }.first(4)
    tips.map { |tip| annotate_target_hit(tip) }
  end

  # Every product-linked component of every meal today, densest-calorie first.
  def reducible_items
    @log.meal_entries.includes(items: :product).flat_map(&:items).select do |item|
      item.calories >= MIN_SAVINGS_KCAL && item.protein_share < PROTEIN_SHARE_FLOOR
    end
  end

  def tip_for(item)
    product = item.product
    meal_name = item.meal_entry.name

    # Prefer cutting half: "use 15 g instead of 30 g of dressing on Power salad".
    # Fall back to skipping the whole thing when half isn't enough to matter.
    half_grams = (item.grams.to_f * MAX_CUT_FRACTION).round
    half_kcal = product.nutrition_for(half_grams)[:calories]

    if half_kcal >= MIN_SAVINGS_KCAL && half_grams.positive?
      remaining = (item.grams.to_f - half_grams).round
      build_tip(
        "Use #{remaining} g of #{product.name} instead of #{item.grams.to_f.round} g on #{meal_name}",
        half_kcal
      )
    elsif item.calories >= MIN_SAVINGS_KCAL
      build_tip("Skip the #{product.name} on #{meal_name}", item.calories)
    end
  end

  def protein_tips
    return [] unless protein_shortfall >= PROTEIN_THRESHOLD

    protein_sources.filter_map do |product|
      serving = product.default_quantity_g.to_f
      next unless serving.positive?

      nutrition = product.nutrition_for(serving)
      next unless nutrition[:protein].to_f >= PROTEIN_THRESHOLD

      Suggestion.new(
        message: "Add #{product.serving_label.presence || "#{serving.round} g"} of #{product.name}",
        savings_kcal: 0,
        adds_protein_g: nutrition[:protein]
      )
    end.first(3)
  end

  # Prefer products already flagged for one-tap logging; fall back to anything
  # with a meaningful protein density so the tip list isn't empty on a fresh DB.
  def protein_sources
    preferred = Product.where(quick_log: true)
      .where("protein_per_100g >= ?", 10)
      .order(protein_per_100g: :desc)
      .limit(5)
    return preferred.to_a if preferred.any?

    Product.where("protein_per_100g >= ?", 10).order(protein_per_100g: :desc).limit(5).to_a
  end

  def build_tip(message, savings_kcal)
    Suggestion.new(message: message, savings_kcal: savings_kcal, adds_protein_g: 0)
  end

  def annotate_target_hit(tip)
    return tip unless tip.savings_kcal.positive?
    return tip unless (@log.total_calories - tip.savings_kcal) <= (@log.calorie_target + CALORIE_THRESHOLD)

    Suggestion.new(
      message: "#{tip.message} — would hit today's target",
      savings_kcal: tip.savings_kcal,
      adds_protein_g: tip.adds_protein_g
    )
  end
end
