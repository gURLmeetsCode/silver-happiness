# frozen_string_literal: true

require "prawn"
require "prawn/table"

# Printable metrics snapshot for sharing or keeping offline. Text + tables only
# (no Chart.js) so it works on the Pi without a browser.
class MetricsReportPdf
  Prawn::Fonts::AFM.hide_m17n_warning = true

  def self.render(goal:, today:, week:, trends:, cycle:)
    new(goal:, today:, week:, trends:, cycle:).render
  end

  def initialize(goal:, today:, week:, trends:, cycle:)
    @goal = goal
    @today = today
    @week = week
    @trends = trends
    @cycle = cycle
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 48) do |pdf|
      pdf.font "Helvetica"
      header(pdf)
      today_block(pdf)
      trends_block(pdf)
      week_block(pdf)
      cycle_block(pdf)
      pdf.number_pages "Silver Happiness - page <page> of <total>",
        at: [ pdf.bounds.left, -28 ],
        width: pdf.bounds.width,
        align: :center,
        size: 8,
        color: "666666"
    end.render
  end

  private

  def header(pdf)
    pdf.text "Silver Happiness - Metrics", size: 20, style: :bold
    pdf.move_down 4
    name = ascii(@goal.greeting_name.presence || "Progress")
    pdf.text "#{name} - #{Date.current.strftime("%A, %-d %B %Y")}",
      size: 10, color: "555555"
    pdf.move_down 16
  end

  def today_block(pdf)
    section(pdf, "Today")
    pdf.table([
      [ "Weight", @today.weight_kg.present? ? "#{@today.weight_kg} kg" : "-" ],
      [ "Eaten", "#{@today.total_calories} kcal (target ~#{@today.calorie_target})" ],
      [ "Burned", "#{@today.calories_burned} kcal / net #{@today.net_calories}" ],
      [ "Protein", "#{@today.total_protein.round(0)} g (goal #{@goal.protein_min_g}-#{@goal.protein_max_g})" ],
      [ "Sleep", ascii(@today.sleep_summary.presence || "-") ],
      [ "Water", "#{@today.water_ml} ml" ]
    ], column_widths: [ 120, 350 ], cell_style: { borders: [], padding: [ 3, 4 ], size: 10 })
    pdf.move_down 14
  end

  def trends_block(pdf)
    section(pdf, "Patterns (last #{MetricsTrends::LOOKBACK_DAYS} days)")
    pdf.text ascii(@trends.headline), size: 10, color: "333333"
    pdf.move_down 8

    if @trends.ready?
      rows = [
        [ "Avg eaten", @trends.avg_eaten ? "#{@trends.avg_eaten} kcal/day" : "-" ],
        [ "Maintenance (TDEE)", @trends.tdee ? "#{@trends.tdee} kcal/day" : "-" ],
        [ "Gap vs TDEE", gap_label ],
        [ "Weekday / weekend avg", weekday_weekend_label ],
        [ "First -> latest weight", weight_change_label ],
        [ "7-day rolling average", @trends.rolling_latest ? "#{@trends.rolling_latest} kg" : "-" ],
        [ "To goal #{@trends.target_weight} kg", @trends.kg_to_goal ? "#{@trends.kg_to_goal} kg" : "-" ]
      ]
      pdf.table(rows, column_widths: [ 150, 320 ], cell_style: { borders: [], padding: [ 3, 4 ], size: 10 })
      pdf.move_down 10

      @trends.insights.each do |insight|
        pdf.text ascii(insight.title), size: 10, style: :bold
        pdf.text ascii(insight.body), size: 9, color: "444444"
        pdf.move_down 6
      end

      if @trends.spikes.any?
        pdf.move_down 4
        pdf.text "Highest calorie days", size: 10, style: :bold
        spike_rows = @trends.spikes.map { |s|
          [ s.date.strftime("%b %-d"), "#{s.calories} kcal", ascii(s.label) ]
        }
        pdf.table([ [ "Date", "Eaten", "Note" ] ] + spike_rows,
          header: true,
          column_widths: [ 70, 80, 320 ],
          cell_style: { size: 9, padding: 4 })
      end
    else
      pdf.text "Not enough logged days yet for a trend read.", size: 10, color: "666666"
    end
    pdf.move_down 14
  end

  def week_block(pdf)
    section(pdf, "This week - #{ascii(@week.week_label)}")
    deficit = if @week.deficit_ready?
      "#{@week.week_deficit_kcal} kcal (~ #{@week.projected_week_loss_kg} kg)"
    else
      "-"
    end
    pdf.table([
      [ "Avg weight", @week.avg_weight ? "#{@week.avg_weight} kg" : "-" ],
      [ "Total eaten", "#{@week.total_eaten} kcal" ],
      [ "Total burned", "#{@week.total_burned} kcal" ],
      [ "Protein days on target", "#{@week.days_on_protein_target} / #{@week.logs.size}" ],
      [ "Week deficit", deficit ]
    ], column_widths: [ 150, 320 ], cell_style: { borders: [], padding: [ 3, 4 ], size: 10 })
    pdf.move_down 14
  end

  def cycle_block(pdf)
    section(pdf, "Cycle and the scale")
    pdf.text ascii(@cycle.summary), size: 9, color: "444444"
  end

  def section(pdf, title)
    pdf.text title, size: 13, style: :bold
    pdf.move_down 6
  end

  def gap_label
    return "-" unless @trends.gap_vs_tdee

    g = @trends.gap_vs_tdee
    g >= 0 ? "-#{g} kcal/day (under)" : "+#{g.abs} kcal/day (over)"
  end

  def weekday_weekend_label
    w = @trends.weekday_avg
    e = @trends.weekend_avg
    return "-" unless w || e

    "Weekdays ~#{w || "-"} / weekends ~#{e || "-"} kcal"
  end

  def weight_change_label
    return "-" unless @trends.first_weight && @trends.last_weight

    "#{@trends.first_weight} -> #{@trends.last_weight} kg (#{@trends.weight_delta} kg)"
  end

  # Built-in Helvetica is Windows-1252; strip fancy punctuation from user text.
  def ascii(text)
    text.to_s
      .gsub("\u2014", "-").gsub("\u2013", "-").gsub("\u2212", "-")
      .gsub("\u201C", '"').gsub("\u201D", '"')
      .gsub("\u2018", "'").gsub("\u2019", "'")
      .gsub("\u2248", "~").gsub("\u00B7", "-").gsub("\u00D7", "x")
      .encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
  end
end
