# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Habit suggestion feedbacks", type: :request do
  before { Goal.current }

  it "snoozes a nudge with dismiss" do
    post habit_suggestion_feedbacks_path, params: {
      suggestion_key: "weekend_leak", status: "dismissed"
    }

    expect(response).to redirect_to(root_path)
    feedback = HabitSuggestionFeedback.find_by!(suggestion_key: "weekend_leak")
    expect(feedback).to be_dismissed
    expect(feedback.hidden_until).to eq(Date.current + 7)
  end

  it "permanently hides a nudge marked not helpful" do
    post habit_suggestion_feedbacks_path, params: {
      suggestion_key: "dont_eat_back", status: "not_helpful"
    }

    expect(response).to redirect_to(root_path)
    expect(HabitSuggestionFeedback.find_by!(suggestion_key: "dont_eat_back")).to be_not_helpful
  end

  it "ignores unknown keys" do
    post habit_suggestion_feedbacks_path, params: {
      suggestion_key: "drop_table;", status: "dismissed"
    }

    expect(response).to redirect_to(root_path)
    expect(HabitSuggestionFeedback.count).to eq(0)
  end
end
