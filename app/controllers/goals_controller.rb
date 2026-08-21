class GoalsController < ApplicationController
  def edit
    @goal = Goal.current
    @energy = @goal.energy_estimate
    @suggested_protein = @goal.suggested_protein_range
    @suggested_calories = @goal.suggested_calorie_targets
  end

  def update
    @goal = Goal.current
    @goal.assign_attributes(goal_params)

    recalculate = ActiveModel::Type::Boolean.new.cast(params[:recalculate_targets])
    @goal.apply_suggested_targets! if recalculate

    if @goal.save
      notice = if recalculate
        "Goals updated — protein and calories recalculated from your target weight and profile."
      else
        "Goals updated."
      end
      redirect_to root_path, notice: notice
    else
      @energy = @goal.energy_estimate
      @suggested_protein = @goal.suggested_protein_range
      @suggested_calories = @goal.suggested_calorie_targets
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
