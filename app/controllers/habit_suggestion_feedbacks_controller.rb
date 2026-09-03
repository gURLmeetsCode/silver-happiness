# frozen_string_literal: true

class HabitSuggestionFeedbacksController < ApplicationController
  def create
    key = params[:suggestion_key].to_s
    unless CutHabitSuggestions::TITLES.key?(key)
      return redirect_to root_path
    end

    feedback = HabitSuggestionFeedback.find_or_initialize_by(suggestion_key: key)
    case params[:status].to_s
    when "dismissed"
      feedback.dismiss!
    when "not_helpful"
      feedback.mark_not_helpful!
    end

    redirect_to root_path
  end
end
