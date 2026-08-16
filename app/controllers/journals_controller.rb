# frozen_string_literal: true

class JournalsController < ApplicationController
  def show
    @today = DailyLog.today
    @goal = Goal.current
    @focus_month = parse_month(params[:month]) || Date.current.beginning_of_month
    @entries = DailyLog.with_journal_content.for_month(@focus_month).recent
    @months_with_entries = DailyLog.with_journal_content
      .pluck(:logged_on)
      .map { |d| d.beginning_of_month }
      .uniq
      .sort
      .reverse
  end

  private

  def parse_month(value)
    return nil if value.blank?

    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError, TypeError
    nil
  end
end
