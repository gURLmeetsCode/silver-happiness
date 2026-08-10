class GoalsController < ApplicationController
  def edit
    @goal = Goal.current
    @energy = @goal.energy_estimate
  end

  def update
    @goal = Goal.current

    if @goal.update(goal_params)
      redirect_to root_path, notice: "Goals updated."
    else
      @energy = @goal.energy_estimate
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def goal_params
    params.require(:goal).permit(
      :display_name,
      :target_weight_kg, :starting_weight_kg, :protein_min_g, :protein_max_g,
      :calories_training_day, :calories_rest_day, :target_date, :water_goal_ml,
      :height_cm, :age_years, :sex, :activity_level, :target_deficit_kcal
    )
  end
end
