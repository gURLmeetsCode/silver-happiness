class GoalsController < ApplicationController
  def edit
    @goal = Goal.current
  end

  def update
    @goal = Goal.current

    if @goal.update(goal_params)
      redirect_to root_path, notice: "Goals updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def goal_params
    params.require(:goal).permit(
      :target_weight_kg, :starting_weight_kg, :protein_min_g, :protein_max_g,
      :calories_training_day, :calories_rest_day, :target_date, :water_goal_ml
    )
  end
end
