# frozen_string_literal: true

# Estimates maintenance calories from a body profile (Mifflin–St Jeor) and turns
# a day's eaten total into a deficit or surplus. Used to say whether the week is
# on track for a given kg of loss — not as medical advice.
#
# Safe daily deficit for a petite woman is typically 250–500 kcal (CDC/NIH pace
# of roughly 0.25–0.5 kg per week). Intake is never recommended below 1,200 kcal.
class EnergyEstimate
  KCAL_PER_KG_FAT = 7700
  MIN_INTAKE_KCAL = 1200
  DEFAULT_DEFICIT = 400
  DEFICIT_FLOOR = 250
  DEFICIT_CEILING = 500

  ACTIVITY_MULTIPLIERS = {
    "sedentary" => 1.2,
    "light" => 1.375,
    "moderate" => 1.55,
    "active" => 1.725,
    "very_active" => 1.9
  }.freeze

  ACTIVITY_LABELS = {
    "sedentary" => "Sedentary (desk work, little exercise)",
    "light" => "Light (1–3 easy sessions a week)",
    "moderate" => "Moderate (3–5 sessions a week — runs/strength)",
    "active" => "Active (6–7 sessions a week)",
    "very_active" => "Very active (hard training or physical job)"
  }.freeze

  def initialize(goal, weight_kg: nil)
    @goal = goal
    @weight_kg = weight_kg.presence&.to_d || goal.starting_weight_kg || goal.target_weight_kg
  end

  def ready?
    @weight_kg.to_f.positive? &&
      @goal.height_cm.to_f.positive? &&
      @goal.age_years.to_i.positive?
  end

  # Mifflin–St Jeor (1990), still the usual clinical starting point.
  def bmr
    return nil unless ready?

    base = (10 * @weight_kg.to_f) + (6.25 * @goal.height_cm.to_f) - (5 * @goal.age_years.to_i)
    (female? ? base - 161 : base + 5).round
  end

  def tdee
    return nil unless ready?

    (bmr * multiplier).round
  end

  # Prefer an explicit goal setting; otherwise pick ~400 kcal for her size,
  # clamped so recommended intake stays at or above 1,200.
  def recommended_deficit
    explicit = @goal.target_deficit_kcal
    return explicit if explicit.to_i.positive?

    return DEFAULT_DEFICIT unless ready?

    raw = [ [ (tdee * 0.2).round, DEFICIT_FLOOR ].max, DEFICIT_CEILING ].min
    [ raw, tdee - MIN_INTAKE_KCAL ].min
  end

  def recommended_intake
    return nil unless ready?

    [ tdee - recommended_deficit, MIN_INTAKE_KCAL ].max
  end

  def expected_weekly_loss_kg
    ((recommended_deficit * 7).to_f / KCAL_PER_KG_FAT).round(2)
  end

  def deficit_for(eaten)
    return nil unless ready?

    tdee - eaten.to_i
  end

  def kg_from_kcal(kcal)
    (kcal.to_f / KCAL_PER_KG_FAT).round(2)
  end

  def activity_label
    ACTIVITY_LABELS.fetch(@goal.activity_level.to_s, ACTIVITY_LABELS["moderate"])
  end

  def summary_line
    return "Add height, age and weight in Goals to estimate your deficit." unless ready?

    "Maintenance ~#{tdee} kcal (BMR #{bmr} × #{activity_label.split(' (').first.downcase}). " \
      "A #{recommended_deficit} kcal/day deficit targets ~#{expected_weekly_loss_kg} kg/week."
  end

  private

  def female?
    @goal.sex.to_s != "male"
  end

  def multiplier
    ACTIVITY_MULTIPLIERS.fetch(@goal.activity_level.to_s, ACTIVITY_MULTIPLIERS["moderate"])
  end
end
