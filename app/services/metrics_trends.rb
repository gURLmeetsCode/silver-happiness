# frozen_string_literal: true

# Longer-window patterns for Metrics: rolling weight, weekday/weekend calories,
# maintenance gap, and the spikes that stall the cut. Complements WeeklySummary
# (this week) and WeightCycleInsight (period water).
class MetricsTrends
  LOOKBACK_DAYS = 28
  COMPLETE_KCAL = 900
  TREAT_NAME = /brownie|pancake|crêpe|crepe|binge|m&m|ice cream|chips/i
  HIGH_TREAT_KCAL = 500

  Insight = Data.define(:title, :body, :tone)
  Spike = Data.define(:date, :calories, :label)

  Result = Data.define(
    :ready,
    :headline,
    :insights,
    :rolling_weight_series,
    :weight_series,
    :weekly_avg_eaten,
    :weekday_avg,
    :weekend_avg,
    :avg_eaten,
    :tdee,
    :gap_vs_tdee,
    :first_weight,
    :last_weight,
    :weight_delta,
    :rolling_latest,
    :target_weight,
    :kg_to_goal,
    :expected_kg_from_intake,
    :complete_days,
    :spikes
  ) do
    def ready?
      ready
    end
  end

  def self.call(goal:, as_of: Date.current)
    new(goal:, as_of:).call
  end

  def initialize(goal:, as_of:)
    @goal = goal
    @as_of = as_of.to_date
  end

  def call
    return empty_result if @goal.life_stage_pregnancy?
    return empty_result if complete_days.size < 5 && weighed.size < 3

    energy = @goal.energy_estimate(weight_kg: last_weight || @goal.starting_weight_kg)
    tdee = energy.ready? ? energy.tdee : nil
    avg = average_calories(complete_days)
    gap = (tdee && avg) ? (tdee - avg).round : nil
    expected = if energy.ready? && avg
      energy.kg_from_kcal((tdee - avg) * complete_days.size)
    end

    insights = build_insights(
      avg:, tdee:, gap:, expected:,
      weekday: average_calories(weekday_days),
      weekend: average_calories(weekend_days)
    )

    Result.new(
      ready: true,
      headline: headline_for(gap, avg, tdee),
      insights: insights,
      rolling_weight_series: rolling_series,
      weight_series: weighed.map { |d| [ chart_label(d.logged_on), d.weight_kg.to_f ] },
      weekly_avg_eaten: weekly_averages,
      weekday_avg: average_calories(weekday_days),
      weekend_avg: average_calories(weekend_days),
      avg_eaten: avg,
      tdee: tdee,
      gap_vs_tdee: gap,
      first_weight: first_weight,
      last_weight: last_weight,
      weight_delta: weight_delta,
      rolling_latest: rolling_latest,
      target_weight: @goal.target_weight_kg.to_f,
      kg_to_goal: last_weight ? (last_weight - @goal.target_weight_kg.to_f).round(1) : nil,
      expected_kg_from_intake: expected,
      complete_days: complete_days.size,
      spikes: spikes.first(5)
    )
  end

  private

  def empty_result
    Result.new(
      ready: false,
      headline: "Log about a week of meals and weigh-ins to see trends.",
      insights: [],
      rolling_weight_series: [],
      weight_series: [],
      weekly_avg_eaten: [],
      weekday_avg: nil,
      weekend_avg: nil,
      avg_eaten: nil,
      tdee: nil,
      gap_vs_tdee: nil,
      first_weight: nil,
      last_weight: nil,
      weight_delta: nil,
      rolling_latest: nil,
      target_weight: @goal.target_weight_kg.to_f,
      kg_to_goal: nil,
      expected_kg_from_intake: nil,
      complete_days: 0,
      spikes: []
    )
  end

  def logs
    @logs ||= DailyLog
      .includes(:meal_entries, :workouts)
      .where(logged_on: (@as_of - LOOKBACK_DAYS + 1)..@as_of)
      .order(:logged_on)
      .to_a
  end

  def complete_days
    @complete_days ||= logs.select { |d| d.total_calories >= COMPLETE_KCAL }
  end

  def weighed
    @weighed ||= logs.select { |d| d.weight_kg.present? }
  end

  def weekday_days
    complete_days.reject { |d| d.logged_on.saturday? || d.logged_on.sunday? }
  end

  def weekend_days
    complete_days.select { |d| d.logged_on.saturday? || d.logged_on.sunday? }
  end

  def average_calories(days)
    return nil if days.empty?

    (days.sum(&:total_calories) / days.size.to_f).round
  end

  def first_weight
    weighed.first&.weight_kg&.to_f
  end

  def last_weight
    weighed.last&.weight_kg&.to_f
  end

  def weight_delta
    return nil unless first_weight && last_weight

    (last_weight - first_weight).round(1)
  end

  def rolling_latest
    rolling_series.last&.last
  end

  def rolling_series
    @rolling_series ||= weighed.each_with_index.map do |day, index|
      window = weighed[[ index - 6, 0 ].max..index]
      avg = (window.sum { |d| d.weight_kg.to_f } / window.size).round(2)
      [ chart_label(day.logged_on), avg ]
    end
  end

  def weekly_averages
    complete_days.group_by { |d| d.logged_on.beginning_of_week }.map do |week_start, days|
      label = week_start.strftime("%-d %b")
      [ label, (days.sum(&:total_calories) / days.size.to_f).round ]
    end
  end

  def spikes
    complete_days
      .select { |d| d.total_calories >= 2100 }
      .sort_by { |d| -d.total_calories }
      .map do |d|
        treats = d.meal_entries.select { |m| m.calories.to_i >= HIGH_TREAT_KCAL && m.name.match?(TREAT_NAME) }
        label = if treats.any?
          treats.max_by { |m| m.calories.to_i }.name
        else
          d.meal_entries.max_by { |m| m.calories.to_i }&.name || "High day"
        end
        Spike.new(date: d.logged_on, calories: d.total_calories, label: label.truncate(48))
      end
  end

  def headline_for(gap, avg, tdee)
    if gap.nil? || avg.nil?
      "Trends from the last #{LOOKBACK_DAYS} days."
    elsif gap >= 150
      "Eating ~#{gap} kcal/day under maintenance — the cut should show on the 7-day average."
    elsif gap <= -50
      "Average intake (~#{avg}) is at or above maintenance (~#{tdee}) — that stalls fat loss even with lots of running."
    else
      "Average intake (~#{avg}) is roughly maintenance (~#{tdee}) — weekdays may look fine while weekends cancel them."
    end
  end

  def build_insights(avg:, tdee:, gap:, expected:, weekday:, weekend:)
    items = []

    if rolling_latest && first_weight && last_weight
      items << Insight.new(
        title: "7-day average vs daily noise",
        body: "Latest 7-day average #{rolling_latest} kg (range this window #{weighed.map { |d| d.weight_kg.to_f }.min}–#{weighed.map { |d| d.weight_kg.to_f }.max} kg). " \
              "Change since first weigh-in: #{weight_delta} kg. Trust the rolling line, not one morning.",
        tone: :info
      )
    end

    if weekday && weekend && weekend_days.size >= 2 && weekend >= weekday + 200
      items << Insight.new(
        title: "Weekends are the leak",
        body: "Weekdays average ~#{weekday} kcal; weekends ~#{weekend}. That gap is large enough to erase a quiet week.",
        tone: :warning
      )
    end

    if tdee && avg && gap
      tone = gap >= 150 ? :success : :warning
      items << Insight.new(
        title: "Intake vs maintenance",
        body: "Last #{complete_days.size} complete days averaged ~#{avg} kcal vs TDEE ~#{tdee} (#{gap >= 0 ? "−" : "+"}#{gap.abs}/day). " \
              "From intake alone that predicts about #{expected} kg over this window" \
              "#{weight_delta ? " (scale moved #{weight_delta} kg)" : ""}. " \
              "Training target already includes the run — don't eat exercise calories twice.",
        tone: tone
      )
    end

    if spikes.any?
      top = spikes.first
      items << Insight.new(
        title: "High days stall the average",
        body: "Biggest day: #{top.date.strftime('%b %-d')} at #{top.calories} kcal (#{top.label}). " \
              "After 2,100+ kcal days the next morning is usually up; under 1,800 days trend down.",
        tone: :warning
      )
    end

    if last_weight && @goal.target_weight_kg
      left = (last_weight - @goal.target_weight_kg.to_f).round(1)
      if left.positive?
        items << Insight.new(
          title: "#{left} kg to goal (#{@goal.target_weight_kg} kg)",
          body: "You don't need more running. Holding weekdays and trimming weekend/treat spikes toward ~1,700 average reopens a real deficit.",
          tone: :info
        )
      end
    end

    items.first(5)
  end

  def chart_label(date)
    date.strftime("%b %-d")
  end
end
