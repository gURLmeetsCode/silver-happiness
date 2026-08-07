class MealEntriesController < ApplicationController
  before_action :set_daily_log
  before_action :set_entry, only: [ :edit, :update, :destroy, :log_water ]

  def create
    @entry = @daily_log.meal_entries.build

    if params[:meal_template_id].present?
      build_from_template
    elsif params[:product_id].present?
      build_from_product
    else
      @entry.assign_attributes(meal_entry_params)
    end

    if @entry.save
      redirect_to @daily_log, notice: "#{@entry.name} added."
    else
      redirect_to @daily_log, alert: @entry.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @entry.update(meal_entry_params)
      redirect_to @daily_log, notice: "#{@entry.name} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to @daily_log, notice: "Meal removed."
  end

  def log_water
    if @entry.water_logged?
      redirect_to @daily_log, notice: "Water already logged for #{@entry.name}."
    elsif @entry.log_water_with_meal!
      redirect_to @daily_log, notice: "+#{@entry.water_suggestion_ml} ml water with #{@entry.name} (#{@daily_log.water_ml} ml today)."
    else
      redirect_to @daily_log, alert: "Could not log water."
    end
  end

  private

  def set_daily_log
    @daily_log = DailyLog.find(params[:daily_log_id])
  end

  def set_entry
    @entry = @daily_log.meal_entries.find(params[:id])
  end

  def build_from_template
    template = MealTemplate.find(params[:meal_template_id])
    @entry.assign_attributes(
      meal_template: template,
      name: params.dig(:meal_entry, :name).presence || template.name,
      meal_type: params.dig(:meal_entry, :meal_type).presence || template.meal_type,
      calories: template.total_calories,
      protein_g: template.total_protein,
      carbs_g: template.total_carbs,
      fat_g: template.total_fat,
      water_suggestion_ml: template.water_suggestion_ml
    )

    apply_meal_entry_overrides
  end

  def apply_meal_entry_overrides
    return unless params[:meal_entry].present?

    @entry.assign_attributes(meal_entry_params)
  end

  def build_from_product
    product = Product.find(params[:product_id])
    quantity = params[:quantity_g].to_d
    nutrition = product.nutrition_for(quantity)

    @entry.assign_attributes(
      meal_type: params[:meal_type].presence || :snack,
      name: params[:name].presence || "#{quantity.to_i}g #{product.name}",
      calories: nutrition[:calories],
      protein_g: nutrition[:protein],
      carbs_g: nutrition[:carbs],
      fat_g: nutrition[:fat],
      notes: params[:notes]
    )
  end

  def meal_entry_params
    params.require(:meal_entry).permit(
      :meal_type, :name, :calories, :protein_g, :carbs_g, :fat_g, :notes
    )
  end
end
