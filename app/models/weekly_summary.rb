# frozen_string_literal: true

class WeeklySummary
  attr_reader :goal, :week_start, :logs

  def initialize(date = Date.current)
    @goal = Goal.current
    @week_start = date.beginning_of_week
    @logs = DailyLog.for_week_of(date).includes(:meal_entries, :workouts)
  end

  def week_label
    "#{week_start.strftime('%-d %b')} – #{week_start.end_of_week.strftime('%-d %b %Y')}"
  end

  def weight_entries
    logs.select { |l| l.weight_kg.present? }
  end

  def latest_weight
    weight_entries.last&.weight_kg
  end

  def avg_weight
    return nil if weight_entries.empty?

    (weight_entries.sum(&:weight_kg) / weight_entries.size.to_f).round(1)
  end

  def period_days_this_week
    logs.count(&:on_period?)
  end

  def period_weigh_ins_this_week
    weight_entries.count(&:on_period?)
  end

  def total_eaten
    logs.sum(&:total_calories)
  end

  def total_burned
    logs.sum(&:calories_burned)
  end

  def total_protein
    logs.sum(&:total_protein).round(0)
  end

  def avg_daily_protein
    return 0 if logs.empty?

    (total_protein / logs.size.to_f).round(0)
  end

  def days_on_protein_target
    logs.count { |l| goal.protein_status(l.total_protein) == :on_target }
  end

  def eaten_by_day
    logs.map { |l| [ chart_label(l.logged_on), l.total_calories ] }
  end

  def burned_by_day
    logs.map { |l| [ chart_label(l.logged_on), l.calories_burned ] }
  end

  def target_by_day
    logs.map { |l| [ chart_label(l.logged_on), l.calorie_target ] }
  end

  def protein_by_day
    logs.map { |l| [ chart_label(l.logged_on), l.total_protein.to_f ] }
  end

  def weight_by_day
    weight_entries.map { |l| [ chart_label(l.logged_on), l.weight_kg.to_f ] }
  end

  def target_weight_line
    logs.map { |l| [ chart_label(l.logged_on), goal.target_weight_kg.to_f ] }
  end

  def protein_min_line
    logs.map { |l| [ chart_label(l.logged_on), goal.protein_min_g.to_f ] }
  end

  def chart_label(date)
    date.strftime("%a %-d")
  end

  def calorie_balance_status
    avg_eaten = logs.any? ? (total_eaten / logs.size.to_f).round(0) : 0
    avg_target = logs.any? ? (logs.sum(&:calorie_target) / logs.size.to_f).round(0) : goal.calories_rest_day

    if (avg_eaten - avg_target).abs <= 150
      :on_target
    elsif avg_eaten > avg_target + 150
      :above_target
    else
      :below_target
    end
  end

  # Uses the latest logged weight when available so the estimate tracks the scale.
  def energy
    @energy ||= goal.energy_estimate(weight_kg: latest_weight)
  end

  def deficit_ready?
    energy.ready? && logs.any?
  end

  def daily_deficit
    return [] unless energy.ready?

    logs.map { |log| [ chart_label(log.logged_on), energy.deficit_for(log.total_calories) ] }
  end

  def planned_deficit_line
    return [] unless energy.ready?

    logs.map { |log| [ chart_label(log.logged_on), energy.recommended_deficit ] }
  end

  # Running total of (maintenance − eaten) across the week so far.
  def cumulative_deficit_by_day
    return [] unless energy.ready?

    running = 0
    logs.map do |log|
      running += energy.deficit_for(log.total_calories)
      [ chart_label(log.logged_on), running ]
    end
  end

  def planned_cumulative_deficit_by_day
    return [] unless energy.ready?

    logs.each_with_index.map do |log, index|
      [ chart_label(log.logged_on), energy.recommended_deficit * (index + 1) ]
    end
  end

  def week_deficit_kcal
    return 0 unless energy.ready?

    logs.sum { |log| energy.deficit_for(log.total_calories) }
  end

  def projected_week_loss_kg
    energy.kg_from_kcal(week_deficit_kcal)
  end

  def planned_week_loss_kg
    return nil unless energy.ready?

    energy.kg_from_kcal(energy.recommended_deficit * [ logs.size, 1 ].max)
  end

  # Are we within ~0.1 kg of the planned pace for the days logged so far?
  def deficit_pace_status
    return :unknown unless deficit_ready?

    planned = energy.recommended_deficit * logs.size
    delta = week_deficit_kcal - planned
    band = energy.recommended_deficit * 0.25

    if delta.abs <= band
      :on_target
    elsif week_deficit_kcal > planned
      :below_target # eating less than planned → ahead on loss
    else
      :above_target # eating more than planned → behind on loss
    end
  end
end
