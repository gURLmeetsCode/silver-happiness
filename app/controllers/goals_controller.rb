class GoalsController < ApplicationController
  def edit
    @goal = Goal.current
    prepare_form_context
  end

  def update
    @goal = Goal.current
    @goal.assign_attributes(goal_params)

    if @goal.life_stage_pregnancy? && @goal.pre_pregnancy_weight_kg.blank?
      @goal.pre_pregnancy_weight_kg = @goal.starting_weight_kg
    end

    recalculate = ActiveModel::Type::Boolean.new.cast(params[:recalculate_targets])
    @goal.apply_suggested_targets! if recalculate

    if @goal.save
      notice = if recalculate
        "Goals updated — protein and calories recalculated from your profile."
      else
        "Goals updated."
      end
      redirect_to root_path, notice: notice
    else
      prepare_form_context
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def prepare_form_context
    @energy = @goal.energy_estimate
    @suggested_protein = @goal.suggested_protein_range
    @suggested_calories = @goal.suggested_calorie_targets
    @pregnancy_guide = @goal.gestational_weight_guidance if @goal.life_stage_pregnancy?
  end

  def goal_params
    params.require(:goal).permit(
      :display_name,
      :life_stage,
      :pre_pregnancy_weight_kg, :pregnancy_confirmed_on, :pregnancy_lmp_on, :pregnancy_due_on,
      :exercise_cleared_by_clinician,
      :target_weight_kg, :starting_weight_kg, :protein_min_g, :protein_max_g,
      :calories_training_day, :calories_rest_day, :target_date, :water_goal_ml,
      :height_cm, :age_years, :sex, :activity_level, :target_deficit_kcal
    )
  end
end
