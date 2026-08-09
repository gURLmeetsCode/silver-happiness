class RecipesController < ApplicationController
  include GroceryHelper

  before_action :set_recipe, only: [ :show, :edit, :update, :archive, :tired_of, :restore, :react ]
  before_action :load_products, only: [ :new, :create, :edit, :update ]

  def index
    base = Recipe.includes(:recipe_ingredients, :meal_template).ordered
    @show_archived = params[:show_archived] == "1"

    visible = @show_archived ? base : base.visible
    @filter = params[:filter]

    filtered = if @filter.present? && Recipe.meal_types.key?(@filter)
      visible.where(meal_type: @filter)
    else
      visible
    end

    @active_regular = filtered.status_active.regular
    @tired_recipes = filtered.status_tired_of
    @suggested_recipes = filtered.status_active.suggested
    @archived_count = Recipe.status_archived.count
    @archived_recipes = base.status_archived if @show_archived
    @recipes = filtered
  end

  def show
    @products = Product.order(:name)
  end

  def new
    @recipe = Recipe.new(user_created: true, regular_meal: true, status: :active)
    5.times { @recipe.recipe_ingredients.build }
  end

  def create
    @recipe = Recipe.new(recipe_params.merge(user_created: true, status: :active))

    if @recipe.save
      redirect_to @recipe, notice: "Recipe saved."
    else
      @recipe.recipe_ingredients.build while @recipe.recipe_ingredients.size < 5
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @recipe.editable?
      redirect_to @recipe, alert: "Only your own recipes can be edited here — use My tweaks for changes."
      return
    end

    @recipe.recipe_ingredients.build while @recipe.recipe_ingredients.size < 3
  end

  def update
    permitted = @recipe.editable? ? recipe_params : personal_params

    if @recipe.update(permitted)
      redirect_to @recipe, notice: @recipe.editable? ? "Recipe updated." : "My tweaks saved."
    elsif @recipe.editable?
      @recipe.recipe_ingredients.build while @recipe.recipe_ingredients.size < 3
      render :edit, status: :unprocessable_entity
    else
      render :show, status: :unprocessable_entity
    end
  end

  def react
    reaction = params[:reaction]
    unless %w[none up down].include?(reaction)
      redirect_to @recipe, alert: "Invalid reaction."
      return
    end

    @recipe.update!(reaction: reaction)
    redirect_to @recipe, notice: reaction == "none" ? "Reaction cleared." : "Thanks — noted!"
  end

  def archive
    @recipe.update!(status: :archived)
    redirect_to recipes_path, notice: "#{@recipe.name} archived."
  end

  def tired_of
    @recipe.update!(status: :tired_of)
    redirect_to recipes_path, notice: "#{@recipe.name} marked as tired of — moved off your regular list."
  end

  def restore
    @recipe.update!(status: :active)
    redirect_to @recipe, notice: "#{@recipe.name} is active again."
  end

  def grocery
    @shopping_period = ShoppingPeriod.current
    @next_reset = ShoppingPeriod.next
    @checked_keys = GroceryCheck.checked_keys_for(@shopping_period)
    @grouped = Recipe.grocery_list.group_by(&:grocery_category)
    @staples = YAML.load_file(Rails.root.join("config/grocery_staples.yml"))
    @batch_prep = Recipe.where(slug: %w[baked-tofu quinoa-batch balsamic-dressing]).index_by(&:slug)
    @batch_prep_items = batch_prep_grocery_items(@batch_prep)
    @total_items = grocery_total_count(@staples, @grouped, @batch_prep_items)
    @checked_count = @checked_keys.size
  end

  # A retired recipe is usually a saved home-screen shortcut, so send it to the
  # list rather than a dead end. Registered after the app-wide 404 handler, which
  # means it wins for recipes only.
  rescue_from ActiveRecord::RecordNotFound, with: :recipe_no_longer_exists

  private

  def recipe_no_longer_exists(_error)
    redirect_to recipes_path, alert: "That recipe no longer exists. Here's everything you have."
  end

  def set_recipe
    @recipe = Recipe.includes(:recipe_ingredients, :meal_template).find(params[:id])
  end

  def load_products
    @products = Product.order(:name)
  end

  def personal_params
    params.require(:recipe).permit(:personal_notes, :reaction)
  end

  def recipe_params
    params.require(:recipe).permit(
      :name, :meal_type, :description, :steps, :prep_time, :serves,
      :protein_g, :calories, :regular_meal, :water_suggestion_ml,
      recipe_ingredients_attributes: [ :id, :name, :amount, :grocery_category, :position, :product_id, :quantity_g, :_destroy ]
    )
  end
end
