# frozen_string_literal: true

# Gestational weight-gain guidance from the National Academy of Medicine
# (formerly IOM, 2009), endorsed by ACOG for counseling. This is not medical
# advice — your obstetric clinician decides with fetal growth in mind.
#
# Ranges are for singleton pregnancy by pre-pregnancy BMI (WHO categories).
# This app highlights the LOWER bound of each range as the mindful target.
class GestationalWeightGuidance
  LB_TO_KG = 0.45359237

  # total_min/max from IOM lbs; weekly rate is 2nd/3rd trimester mean (kg/week).
  BANDS = [
    {
      bmi_max: 18.5,
      key: :underweight,
      label: "underweight",
      total_min_kg: (28 * LB_TO_KG).round(1),
      total_max_kg: (40 * LB_TO_KG).round(1),
      weekly_kg: (1.0 * LB_TO_KG).round(2)
    },
    {
      bmi_max: 25.0,
      key: :normal,
      label: "normal weight",
      total_min_kg: (25 * LB_TO_KG).round(1),
      total_max_kg: (35 * LB_TO_KG).round(1),
      weekly_kg: (1.0 * LB_TO_KG).round(2)
    },
    {
      bmi_max: 30.0,
      key: :overweight,
      label: "overweight",
      total_min_kg: (15 * LB_TO_KG).round(1),
      total_max_kg: (25 * LB_TO_KG).round(1),
      weekly_kg: (0.6 * LB_TO_KG).round(2)
    },
    {
      bmi_max: Float::INFINITY,
      key: :obese,
      label: "obese",
      total_min_kg: (11 * LB_TO_KG).round(1),
      total_max_kg: (20 * LB_TO_KG).round(1),
      weekly_kg: (0.5 * LB_TO_KG).round(2)
    }
  ].freeze

  SOURCE_LABEL = "IOM/NAM 2009 · ACOG Committee Opinion on weight gain in pregnancy"
  EXERCISE_SOURCE_LABEL = "ACOG Committee Opinion 804 — Physical Activity and Exercise During Pregnancy and the Postpartum Period"

  def self.bmi(weight_kg, height_cm)
    w = weight_kg.to_f
    h_m = height_cm.to_f / 100.0
    return nil unless w.positive? && h_m.positive?

    (w / (h_m * h_m)).round(1)
  end

  def self.band_for_bmi(bmi)
    return nil if bmi.blank?

    BANDS.find { |band| bmi < band[:bmi_max] } || BANDS.last
  end

  def initialize(goal, as_of: Date.current)
    @goal = goal
    @as_of = as_of
  end

  def ready?
    @goal.life_stage_pregnancy? &&
      pre_pregnancy_weight.to_f.positive? &&
      @goal.height_cm.to_f.positive? &&
      gestational_week.present?
  end

  def pre_pregnancy_weight
    @goal.pre_pregnancy_weight_kg.presence || @goal.starting_weight_kg
  end

  def bmi
    self.class.bmi(pre_pregnancy_weight, @goal.height_cm)
  end

  def band
    self.class.band_for_bmi(bmi)
  end

  def gestational_week
    @goal.gestational_week_on(@as_of)
  end

  def trimester
    week = gestational_week
    return nil if week.nil?

    if week <= 13 then 1
    elsif week <= 27 then 2
    else 3
    end
  end

  # Lower-bound expected gain by this week (kg above pre-pregnancy).
  def expected_lower_gain_kg
    week = gestational_week
    return nil if week.nil? || band.nil?

    t1_cap = [ 0.5, band[:total_min_kg] * 0.05 ].max
    if week <= 13
      return (t1_cap * week / 13.0).round(2)
    end

    remaining = [ band[:total_min_kg] - t1_cap, 0 ].max
    (t1_cap + remaining * (week - 13) / 27.0).round(2)
  end

  def expected_lower_weight_kg
    return nil unless expected_lower_gain_kg

    (pre_pregnancy_weight.to_f + expected_lower_gain_kg).round(1)
  end

  def term_lower_weight_kg
    return nil unless band && pre_pregnancy_weight

    (pre_pregnancy_weight.to_f + band[:total_min_kg]).round(1)
  end

  def term_upper_weight_kg
    return nil unless band && pre_pregnancy_weight

    (pre_pregnancy_weight.to_f + band[:total_max_kg]).round(1)
  end

  def current_gain_kg(weight_kg)
    return nil if weight_kg.blank? || pre_pregnancy_weight.blank?

    (weight_kg.to_f - pre_pregnancy_weight.to_f).round(1)
  end

  def gain_status(weight_kg)
    gain = current_gain_kg(weight_kg)
    expected = expected_lower_gain_kg
    return :unknown if gain.nil? || expected.nil? || band.nil?

    upper_now = expected_upper_gain_kg
    if gain < expected - 0.5
      :below_lower_bound
    elsif gain > upper_now + 0.5
      :above_range
    elsif gain <= expected + 0.8
      :on_lower_path
    else
      :within_range
    end
  end

  def expected_upper_gain_kg
    week = gestational_week
    return nil if week.nil? || band.nil?

    t1_cap = [ 2.0, band[:total_max_kg] * 0.15 ].min
    if week <= 13
      return (t1_cap * week / 13.0).round(2)
    end

    remaining = [ band[:total_max_kg] - t1_cap, 0 ].max
    (t1_cap + remaining * (week - 13) / 27.0).round(2)
  end

  def summary_lines
    return [] unless ready?

    [
      "Pre-pregnancy BMI #{bmi} (#{band[:label]}) → IOM gain #{band[:total_min_kg]}–#{band[:total_max_kg]} kg total.",
      "Mindful target: lower bound (~#{band[:total_min_kg]} kg by term ≈ #{term_lower_weight_kg} kg).",
      "Week #{gestational_week} · trimester #{trimester} · lower-path scale today ≈ #{expected_lower_weight_kg} kg.",
      "Source: #{SOURCE_LABEL}. Confirm with your clinician — not medical advice."
    ]
  end
end
