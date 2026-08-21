# frozen_string_literal: true

class Goal < ApplicationRecord
  ACTIVITY_LEVELS = %w[sedentary light moderate active very_active].freeze
  SEXES = %w[female male].freeze

  validates :target_weight_kg, :protein_min_g, :protein_max_g,
            :calories_training_day, :calories_rest_day, presence: true
  validates :protein_max_g, numericality: { greater_than_or_equal_to: :protein_min_g }
  validates :sex, inclusion: { in: SEXES }
  validates :activity_level, inclusion: { in: ACTIVITY_LEVELS }
  validates :height_cm, numericality: { greater_than: 100, less_than: 250 }, allow_nil: true
  validates :age_years, numericality: { greater_than: 15, less_than: 100 }, allow_nil: true
  validates :target_deficit_kcal, numericality: { greater_than: 0, less_than_or_equal_to: 1000 }, allow_nil: true

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
      target_deficit_kcal: 400
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

  def calorie_target_for(log)
    log.training_day? ? calories_training_day : calories_rest_day
  end

  def energy_estimate(weight_kg: nil)
    EnergyEstimate.new(self, weight_kg: weight_kg)
  end

  # Protein range from target weight (goal body size), not current weight.
  def suggested_protein_range
    weight = target_weight_kg.to_f
    return nil unless weight.positive?

    min = (weight * PROTEIN_MIN_PER_KG).round
    max = (weight * PROTEIN_MAX_PER_KG).round
    max = min if max < min
    { min_g: min, max_g: max }
  end

  # Rest/training calorie targets from maintenance − deficit (+ small training buffer).
  def suggested_calorie_targets(weight_kg: nil)
    energy = energy_estimate(weight_kg: weight_kg)
    return nil unless energy.ready?

    rest = energy.recommended_intake
    {
      rest_day: rest,
      training_day: rest + TRAINING_DAY_CALORIE_BUFFER,
      recommended_intake: rest,
      maintenance: energy.tdee,
      deficit: energy.recommended_deficit
    }
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

    (current_weight.to_d - target_weight_kg).round(1)
  end

  def weight_status(current_weight)
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
  end
end
