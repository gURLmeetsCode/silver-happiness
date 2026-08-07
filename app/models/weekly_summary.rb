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
end
