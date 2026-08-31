# frozen_string_literal: true

class WorkoutsController < ApplicationController
  before_action :set_daily_log

  def create
    attrs = workout_params.to_h
    type = attrs["activity_type"].presence || attrs[:activity_type]

    # Run/walk are owned by the daily log fields + sync_run_walk_workouts!.
    # Creating a separate Workout row here used to look fine until the next
    # daily-log save wiped it (empty walk_km/walk_calories → destroy).
    if type.in?(%w[run walk])
      save_run_or_walk!(type, attrs)
    else
      @workout = @daily_log.workouts.build(workout_params)
      if @workout.save
        redirect_to daily_log_path(@daily_log, anchor: "movement"), notice: "Workout added."
      else
        redirect_to daily_log_path(@daily_log, anchor: "movement"),
                    alert: @workout.errors.full_messages.to_sentence
      end
    end
  end

  def destroy
    workout = @daily_log.workouts.find(params[:id])

    if workout.activity_type_run?
      @daily_log.update!(run_km: nil, run_calories: nil)
      redirect_to daily_log_path(@daily_log, anchor: "movement"), notice: "Run removed."
    elsif workout.activity_type_walk?
      @daily_log.update!(walk_km: nil, walk_calories: nil)
      redirect_to daily_log_path(@daily_log, anchor: "movement"), notice: "Walk removed."
    else
      workout.destroy
      redirect_to daily_log_path(@daily_log, anchor: "movement"), notice: "Workout removed."
    end
  end

  private

  def set_daily_log
    @daily_log = DailyLog.find(params[:daily_log_id])
  end

  def workout_params
    params.require(:workout).permit(:activity_type, :distance_km, :calories_burned, :notes)
  end

  def save_run_or_walk!(type, attrs)
    kcal = attrs["calories_burned"].presence || attrs[:calories_burned]
    km = attrs["distance_km"].presence || attrs[:distance_km]
    notes = attrs["notes"].presence || attrs[:notes]

    if kcal.blank? && km.blank?
      redirect_to daily_log_path(@daily_log, anchor: "movement"),
                  alert: "Add calories or distance for #{type}."
      return
    end

    updates = if type == "run"
      { run_calories: kcal.presence&.to_i, run_km: km.presence }
    else
      { walk_calories: kcal.presence&.to_i, walk_km: km.presence }
    end
    updates.compact!

    if notes.present?
      existing = @daily_log.training_notes.to_s
      updates[:training_notes] = [ existing, notes ].map(&:presence).compact.join(" · ")
    end

    if @daily_log.update(updates)
      label = type == "run" ? "Run" : "Walk"
      redirect_to daily_log_path(@daily_log, anchor: "movement"),
                  notice: "#{label} saved (#{@daily_log.public_send(:"#{type}_calories")} kcal)."
    else
      redirect_to daily_log_path(@daily_log, anchor: "movement"),
                  alert: @daily_log.errors.full_messages.to_sentence
    end
  end
end
