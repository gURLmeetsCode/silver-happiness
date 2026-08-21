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
        recalculate_targets: "0",
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
      expect(Goal.current.protein_min_g).to eq(95)
      expect(Goal.current.calories_rest_day).to eq(1650)
    end

    it "recalculates protein and calories from target weight when asked" do
      goal = Goal.current
      goal.update!(
        target_weight_kg: 56,
        protein_min_g: 90,
        protein_max_g: 100,
        calories_rest_day: 1600,
        calories_training_day: 1700
      )

      patch goal_path, params: {
        recalculate_targets: "1",
        goal: {
          target_weight_kg: 54,
          starting_weight_kg: goal.starting_weight_kg,
          protein_min_g: 90,
          protein_max_g: 100,
          calories_training_day: 1700,
          calories_rest_day: 1600
        }
      }

      goal.reload
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to match(/recalculated/i)
      expect(goal.target_weight_kg).to eq(54)
      expect(goal.protein_min_g).to eq(86)
      expect(goal.protein_max_g).to eq(97)
      expect(goal.calories_training_day).to eq(goal.calories_rest_day + 100)
    end

    it "re-renders with 422 when protein max is below protein min" do
      Goal.current

      patch goal_path, params: {
        recalculate_targets: "0",
        goal: { protein_min_g: 120, protein_max_g: 90 }
      }

      expect(response).to have_http_status(422)
    end
  end
end
