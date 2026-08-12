# frozen_string_literal: true

class UrgeCheckInsController < ApplicationController
  before_action :set_daily_log

  def new
    @urge_check_in = @daily_log.urge_check_ins.build(
      protein_status: @daily_log.protein_status_suggestion
    )
    @goal = Goal.current
  end

  def create
    @urge_check_in = @daily_log.urge_check_ins.build(urge_check_in_params)
    @goal = Goal.current

    if @urge_check_in.save
      notice = if @urge_check_in.paused?
        "Urge logged. Nice pause — that still counts."
      else
        "Urge logged. No shame — the note helps next time."
      end
      redirect_to safe_return_to(default: daily_log_path(@daily_log, anchor: "body")), notice: notice
    else
      flash.now[:alert] = @urge_check_in.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_daily_log
    @daily_log = params[:daily_log_id] == "today" ? DailyLog.today : DailyLog.find(params[:daily_log_id])
  end

  def urge_check_in_params
    params.require(:urge_check_in).permit(:feeling, :protein_status, :delay_action, :outcome, :note)
  end
end
