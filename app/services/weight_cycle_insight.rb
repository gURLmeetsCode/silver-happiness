# frozen_string_literal: true

# Relates period check-ins to the scale so water-weight swings are visible
# instead of looking like fat gain/loss.
class WeightCycleInsight
  DAYS = 45

  Result = Struct.new(
    :logs,
    :weight_series,
    :period_weight_series,
    :target_series,
    :on_period_avg,
    :off_period_avg,
    :period_days_with_weight,
    :off_days_with_weight,
    :period_days_in_window,
    keyword_init: true
  ) do
    def enough_to_compare?
      period_days_with_weight >= 2 && off_days_with_weight >= 2
    end

    def cycle_delta
      return nil unless enough_to_compare?

      (on_period_avg - off_period_avg).round(1)
    end

    def summary
      if enough_to_compare?
        delta = cycle_delta
        direction = if delta.positive?
          "about #{delta} kg higher"
        elsif delta.negative?
          "about #{delta.abs} kg lower"
        else
          "about the same"
        end
        "On period days your scale has averaged #{on_period_avg} kg vs #{off_period_avg} kg off " \
          "(#{direction}). Treat bumps during your cycle as water, not a stall."
      elsif period_days_in_window.positive?
        "You’ve marked #{period_days_in_window} period day#{period_days_in_window == 1 ? "" : "s"} " \
          "in the last #{DAYS} days. Keep logging weight on those days — averages will show once " \
          "there are a few on- and off-period weigh-ins."
      else
        "Mark “On my period today” on Body & mood when it applies — then weight charts can " \
          "separate cycle water from real trend."
      end
    end
  end

  def self.call(goal:, as_of: Date.current, days: DAYS)
    new(goal: goal, as_of: as_of, days: days).call
  end

  def initialize(goal:, as_of:, days:)
    @goal = goal
    @as_of = as_of.to_date
    @days = days
  end

  def call
    logs = DailyLog
      .where(logged_on: (@as_of - @days + 1)..@as_of)
      .order(:logged_on)
      .to_a

    weighed = logs.select { |log| log.weight_kg.present? }
    on_period = weighed.select(&:on_period?)
    off_period = weighed.reject(&:on_period?)

    labels = weighed.map { |log| chart_label(log.logged_on) }

    Result.new(
      logs: logs,
      weight_series: weighed.map { |log| [ chart_label(log.logged_on), log.weight_kg.to_f ] },
      period_weight_series: weighed.map { |log|
        [ chart_label(log.logged_on), (log.on_period? ? log.weight_kg.to_f : nil) ]
      },
      target_series: labels.map { |label| [ label, @goal.target_weight_kg.to_f ] },
      on_period_avg: average(on_period),
      off_period_avg: average(off_period),
      period_days_with_weight: on_period.size,
      off_days_with_weight: off_period.size,
      period_days_in_window: logs.count(&:on_period?)
    )
  end

  private

  def average(entries)
    return nil if entries.empty?

    (entries.sum(&:weight_kg) / entries.size.to_f).round(1)
  end

  def chart_label(date)
    date.strftime("%b %-d")
  end
end
