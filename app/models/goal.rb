# frozen_string_literal: true

class Goal < ApplicationRecord
  ACTIVITY_LEVELS = %w[sedentary light moderate active very_active].freeze
  SEXES = %w[female male].freeze
  LIFE_STAGES = %w[standard pregnancy postpartum].freeze

  LIFE_STAGE_LABELS = {
    "standard" => "Weight (fat-loss / maintain)",
    "pregnancy" => "Pregnancy (confirmed)",
    "postpartum" => "Postpartum recovery"
  }.freeze

  validates :target_weight_kg, :protein_min_g, :protein_max_g,
            :calories_training_day, :calories_rest_day, presence: true
  validates :protein_max_g, numericality: { greater_than_or_equal_to: :protein_min_g }
  validates :sex, inclusion: { in: SEXES }
  validates :activity_level, inclusion: { in: ACTIVITY_LEVELS }
  validates :life_stage, inclusion: { in: LIFE_STAGES }
  validates :height_cm, numericality: { greater_than: 100, less_than: 250 }, allow_nil: true
  validates :age_years, numericality: { greater_than: 15, less_than: 100 }, allow_nil: true
  validates :target_deficit_kcal, numericality: { greater_than: 0, less_than_or_equal_to: 1000 }, allow_nil: true
  validate :pregnancy_dates_make_sense

  before_validation :normalize_blank_profile_fields

  def self.current
    first || create!(defaults)
  end

  def self.defaults
    {
      target_weight_kg: 56.0,
      starting_weight_kg: 58.6,
      protein_min_g: 90,
      protein_max_g: 100,
      calories_training_day: 1700,
      calories_rest_day: 1600,
      water_goal_ml: 2000,
      target_date: Date.new(2026, 11, 30),
      height_cm: 163.0,
      age_years: 37,
      sex: "female",
      activity_level: "moderate",
      target_deficit_kcal: 400,
      life_stage: "standard"
    }
  end

  # Protein band used when recalculating from target weight (~1.6–1.8 g/kg).
  # Matches the original defaults: 56 kg → 90–100 g.
  PROTEIN_MIN_PER_KG = 1.6
  PROTEIN_MAX_PER_KG = 1.8
  TRAINING_DAY_CALORIE_BUFFER = 100

  def greeting_name
    display_name.presence
  end

  def life_stage_standard?
    life_stage == "standard"
  end

  def life_stage_pregnancy?
    life_stage == "pregnancy"
  end

  def life_stage_postpartum?
    life_stage == "postpartum"
  end

  def life_stage_label
    LIFE_STAGE_LABELS.fetch(life_stage.to_s, life_stage.to_s.humanize)
  end

  def gestational_weight_guidance(as_of: Date.current)
    GestationalWeightGuidance.new(self, as_of: as_of)
  end

  # Prefer LMP; else back-calculate from due date (LMP ≈ due − 280 days).
  def gestational_week_on(date = Date.current)
    lmp = pregnancy_lmp_on.presence
    lmp ||= pregnancy_due_on - 280.days if pregnancy_due_on.present?
    return nil if lmp.blank?

    days = (date - lmp).to_i
    return nil if days.negative?

    [ (days / 7) + 1, 42 ].min
  end

  def calorie_target_for(log)
    log.training_day? ? calories_training_day : calories_rest_day
  end

  def energy_estimate(weight_kg: nil)
    EnergyEstimate.new(self, weight_kg: weight_kg)
  end

  # Protein range from target weight (goal body size), not current weight.
  # In pregnancy, use pre-pregnancy / current working weight instead of fat-loss target.
  def suggested_protein_range
    weight = if life_stage_pregnancy?
      (pre_pregnancy_weight_kg.presence || starting_weight_kg || target_weight_kg).to_f
    else
      target_weight_kg.to_f
    end
    return nil unless weight.positive?

    min = (weight * PROTEIN_MIN_PER_KG).round
    max = (weight * PROTEIN_MAX_PER_KG).round
    max = min if max < min
    { min_g: min, max_g: max }
  end

  # Rest/training calorie targets. Pregnancy: no deficit — maintenance (+ small training buffer).
  def suggested_calorie_targets(weight_kg: nil)
    energy = energy_estimate(weight_kg: weight_kg)
    return nil unless energy.ready?

    if life_stage_pregnancy?
      rest = energy.tdee
      {
        rest_day: rest,
        training_day: rest + TRAINING_DAY_CALORIE_BUFFER,
        recommended_intake: rest,
        maintenance: energy.tdee,
        deficit: 0
      }
    else
      rest = energy.recommended_intake
      {
        rest_day: rest,
        training_day: rest + TRAINING_DAY_CALORIE_BUFFER,
        recommended_intake: rest,
        maintenance: energy.tdee,
        deficit: energy.recommended_deficit
      }
    end
  end

  # Writes suggested protein (+ calories when the body profile is complete).
  def apply_suggested_targets!(weight_kg: nil)
    if (protein = suggested_protein_range)
      self.protein_min_g = protein[:min_g]
      self.protein_max_g = protein[:max_g]
    end

    if (calories = suggested_calorie_targets(weight_kg: weight_kg))
      self.calories_rest_day = calories[:rest_day]
      self.calories_training_day = calories[:training_day]
    end

    self
  end

  def weight_delta(current_weight)
    return nil if current_weight.blank?

    if life_stage_pregnancy?
      guide = gestational_weight_guidance
      return nil unless guide.ready?

      (current_weight.to_d - guide.expected_lower_weight_kg).round(1)
    else
      (current_weight.to_d - target_weight_kg).round(1)
    end
  end

  def weight_status(current_weight)
    if life_stage_pregnancy?
      guide = gestational_weight_guidance
      return :unknown unless guide.ready?

      case guide.gain_status(current_weight)
      when :on_lower_path, :within_range then :on_target
      when :above_range then :above_target
      when :below_lower_bound then :below_target
      else :unknown
      end
    else
      delta = weight_delta(current_weight)
      return :unknown if delta.nil?

      if delta <= 0.3
        :on_target
      elsif delta.positive?
        :above_target
      else
        :below_target
      end
    end
  end

  def protein_status(grams)
    return :unknown if grams.blank?

    g = grams.to_f
    if g >= protein_min_g && g <= protein_max_g + 5
      :on_target
    elsif g < protein_min_g
      :below_target
    else
      :above_target
    end
  end

  def days_to_target(as_of: Date.current)
    return nil if target_date.blank?

    (target_date - as_of).to_i
  end

  def kg_to_target(current_weight)
    return nil if current_weight.blank? || life_stage_pregnancy?

    (current_weight.to_d - target_weight_kg).round(1)
  end

  def calorie_status(eaten, burned, target)
    return :unknown if eaten.zero? && burned.zero?

    net = eaten - burned
    if (eaten - target).abs <= 150
      :on_target
    elsif eaten > target + 150
      :above_target
    else
      :below_target
    end
  end

  private

  def normalize_blank_profile_fields
    self.target_deficit_kcal = nil if target_deficit_kcal.blank?
    self.height_cm = nil if height_cm.blank?
    self.age_years = nil if age_years.blank?
    self.pre_pregnancy_weight_kg = nil if pre_pregnancy_weight_kg.blank?
    self.pregnancy_confirmed_on = nil if pregnancy_confirmed_on.blank?
    self.pregnancy_lmp_on = nil if pregnancy_lmp_on.blank?
    self.pregnancy_due_on = nil if pregnancy_due_on.blank?
    self.life_stage = "standard" if life_stage.blank?
  end

  def pregnancy_dates_make_sense
    return unless life_stage_pregnancy?

    if pregnancy_lmp_on.blank? && pregnancy_due_on.blank?
      errors.add(:base, "Add LMP or due date so pregnancy week and weight bands can be calculated.")
    end
  end
end
