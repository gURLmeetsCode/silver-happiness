# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Goals", type: :request do
  describe "GET /goal/edit" do
    it "renders the goal form" do
      get edit_goal_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /goal" do
    it "saves valid changes and returns home" do
      Goal.current

      patch goal_path, params: {
        goal: {
          target_weight_kg: 55,
          starting_weight_kg: 62,
          protein_min_g: 95,
          protein_max_g: 110,
          calories_training_day: 1750,
          calories_rest_day: 1650,
          water_goal_ml: 2500
        }
      }

      expect(response).to redirect_to(root_path)
      expect(Goal.current.target_weight_kg).to eq(55)
      expect(Goal.current.water_goal_ml).to eq(2500)
    end

    it "re-renders with 422 when protein max is below protein min" do
      Goal.current

      patch goal_path, params: { goal: { protein_min_g: 120, protein_max_g: 90 } }

      expect(response).to have_http_status(422)
    end
  end
end
