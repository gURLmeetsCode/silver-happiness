# frozen_string_literal: true

# Actionable tips when today's eaten macros miss calorie or protein targets.
class DailyTargetSuggestions
  Suggestion = Data.define(:message, :savings_kcal, :adds_protein_g)

  CALORIE_THRESHOLD = 150
  PROTEIN_THRESHOLD = 5

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
    return "Quick adds to hit protein:" if protein_shortfall >= PROTEIN_THRESHOLD && calorie_overshoot < CALORIE_THRESHOLD

    "Small swaps that would have brought you closer:" if calorie_overshoot >= CALORIE_THRESHOLD
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

    tips = []
    ctx = meal_context

    if ctx[:dressing] || ctx[:salad_meal]
      tips << build_tip("Use 1 tbsp dressing instead of 2", 80)
      tips << build_tip("Try lemon + 1 tsp oil instead of 2 tbsp dressing", 120)
    end

    if ctx[:puget_oil] || ctx[:olive_oil]
      tips << build_tip("Use 1 tbsp Puget olive oil instead of 2", 90)
    end

    if ctx[:avocado]
      tips << build_tip("Use ¼ avocado instead of ½ on your wrap", 60)
    end

    if ctx[:peanut_butter] && ctx[:snack]
      tips << build_tip("Skip the peanut butter on your snack", 35)
    end

    if ctx[:pasta_dinner] && ctx[:puget_oil]
      tips << build_tip("Skip the extra olive oil — 2 tbsp dressing is enough", 90)
    end

    if tips.empty?
      tips << build_tip("Measure oils and dressing — each extra tbsp is ~80–90 kcal", 80)
    end

    tips.map { |tip| annotate_target_hit(tip) }
  end

  def protein_tips
    return [] unless protein_shortfall >= PROTEIN_THRESHOLD

    [
      Suggestion.new(
        message: "Add ½ scoop Vegan Protein 360",
        savings_kcal: 0,
        adds_protein_g: 14
      ),
      Suggestion.new(
        message: "Add 125 g tofu (1 pavé)",
        savings_kcal: 0,
        adds_protein_g: 17.5
      )
    ]
  end

  def meal_context
    @meal_context ||= begin
      ctx = {
        dressing: false, salad_meal: false, puget_oil: false, olive_oil: false,
        avocado: false, peanut_butter: false, snack: false, pasta_dinner: false
      }

      @log.meal_entries.each do |entry|
        blob = "#{entry.name} #{entry.notes}".downcase
        ctx[:salad_meal] = true if blob.match?(/salad|power salad/)
        ctx[:dressing] = true if blob.match?(/dressing|balsamic/)
        ctx[:puget_oil] = true if blob.match?(/puget|huile d'olive/)
        ctx[:olive_oil] = true if blob.match?(/olive oil|huile/)
        ctx[:avocado] = true if blob.match?(/avocado|wrap|chipotle/)
        ctx[:peanut_butter] = true if blob.match?(/pb|cacahu|peanut|koro/)
        ctx[:snack] = true if entry.meal_type_snack?
        ctx[:pasta_dinner] = true if blob.match?(/pasta/)
      end

      ctx
    end
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
