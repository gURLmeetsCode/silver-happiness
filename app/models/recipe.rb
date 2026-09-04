class Recipe < ApplicationRecord
  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2, snack: 3, prep: 4 }, prefix: true
  enum :reaction, { none: 0, up: 1, down: 2 }, prefix: :reaction
  enum :status, { active: 0, tired_of: 1, archived: 2 }, prefix: :status

  belongs_to :meal_template, optional: true
  has_many :recipe_ingredients, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :ingredient_blank?

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :name, uniqueness: { case_sensitive: false, message: "already exists — open that recipe instead of creating a twin" }

  before_validation :generate_slug, on: :create

  scope :ordered, -> { order(:status, :meal_type, :position, :name) }
  scope :regular, -> { where(regular_meal: true) }
  scope :suggested, -> { where(regular_meal: false) }
  scope :visible, -> { where.not(status: :archived) }
  scope :for_grocery, -> { status_active.regular }
  scope :custom, -> { where(user_created: true) }

  validate :must_have_ingredients, on: [ :create, :update ], if: :user_created?

  MEAL_TYPE_LABELS = {
    "breakfast" => "Breakfast",
    "lunch" => "Lunch",
    "dinner" => "Dinner",
    "snack" => "Snack",
    "prep" => "Batch tray"
  }.freeze

  def meal_type_label
    MEAL_TYPE_LABELS[meal_type] || meal_type.humanize
  end

  def macros_label
    if tracked_ingredients.any?
      per = nutrition_per_serving
      parts = []
      parts << "~#{per[:calories]} kcal tracked" if per[:calories].positive?
      parts << "~#{per[:protein].round(0)} g protein tracked" if per[:protein].positive?
      parts << "+ veg/extras" if untracked_ingredients.any?
      parts.join(" · ")
    else
      legacy = []
      legacy << "~#{calories} kcal" if calories.present?
      legacy << "~#{protein_g} g protein" if protein_g.present?
      legacy.join(" · ")
    end
  end

  def tracked_ingredients
    recipe_ingredients.select(&:tracked?)
  end

  def untracked_ingredients
    recipe_ingredients.reject(&:tracked?)
  end

  def calculated_nutrition
    tracked_ingredients.each_with_object({ calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0 }) do |ing, totals|
      n = ing.nutrition
      totals[:calories] += n[:calories]
      totals[:protein] += n[:protein]
      totals[:carbs] += n[:carbs]
      totals[:fat] += n[:fat]
    end
  end

  def nutrition_per_serving
    total = calculated_nutrition
    divisor = serves.to_i.positive? ? serves : 1
    {
      calories: (total[:calories].to_f / divisor).round,
      protein: (total[:protein] / divisor).round(1),
      carbs: (total[:carbs] / divisor).round(1),
      fat: (total[:fat] / divisor).round(1)
    }
  end

  def sync_macros_from_ingredients!
    return unless tracked_ingredients.any?

    per = nutrition_per_serving
    update_columns(
      calories: per[:calories],
      protein_g: per[:protein].round
    )
  end

  def water_prompt
    cups = (water_suggestion_ml / 250.0).round(1)
    label = cups == 1 ? "1 cup" : "#{cups} cups"
    "Try #{label} of water (#{water_suggestion_ml} ml) with this meal"
  end

  def sync_from_meal_template!
    return unless meal_template

    keep_ids = []
    meal_template.meal_template_items.each_with_index do |item, i|
      ing = recipe_ingredients.find_or_initialize_by(product: item.product)
      ing.assign_attributes(
        name: item.product.name,
        amount: item.label.presence || "#{item.quantity_g.to_i} g",
        quantity_g: item.quantity_g,
        grocery_category: grocery_category_for_product(item.product),
        position: i
      )
      ing.save!
      keep_ids << ing.id
    end
    recipe_ingredients.where.not(id: keep_ids).destroy_all
    sync_macros_from_ingredients!
  end

  # Build-a-meal only lists MealTemplates. Keep a linked template in sync so
  # user recipes (e.g. oil-free hummus) show up next to products.
  def ensure_meal_template!
    tracked = tracked_ingredients
    return meal_template if tracked.empty?

    template = meal_template || MealTemplate.find_or_initialize_by(slug: slug)
    template.assign_attributes(
      name: name,
      meal_type: template_meal_type,
      description: description.to_s.truncate(500),
      water_suggestion_ml: water_suggestion_ml
    )
    template.save!

    template.meal_template_items.destroy_all
    tracked.each do |ing|
      template.meal_template_items.create!(
        product: ing.product,
        quantity_g: ing.quantity_g,
        label: ing.amount.presence || "#{ing.quantity_g.to_i} g"
      )
    end

    update_column(:meal_template_id, template.id) if meal_template_id != template.id
    template
  end

  def batch_style?
    meal_type_prep? || name.match?(/\b(batch|tray|full batch)\b/i)
  end

  def reaction_label
    case reaction
    when "up" then "Love it"
    when "down" then "Not for me"
    else nil
    end
  end

  def status_label
    { "active" => "Active", "tired_of" => "Tired of this", "archived" => "Archived" }[status]
  end

  def editable?
    user_created?
  end

  def self.grocery_list
    RecipeIngredient
      .joins(:recipe)
      .merge(Recipe.for_grocery)
      .includes(:recipe)
      .order("recipes.meal_type, recipes.position, recipe_ingredients.position")
  end

  private

  def must_have_ingredients
    present = recipe_ingredients.reject { |i| i.marked_for_destruction? || i.name.blank? }
    errors.add(:base, "Add at least one ingredient") if present.empty?
  end

  def generate_slug
    return if slug.present? || name.blank?

    base = name.parameterize
    candidate = base
    n = 2
    while Recipe.exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def ingredient_blank?(attrs)
    attrs["name"].blank? && attrs["amount"].blank? && attrs["product_id"].blank?
  end

  def grocery_category_for_product(product)
    case product.name
    when /tofu|skyr|yogurt|protein|bean|lentil|hummus|houmous/i then :protein
    when /oat|quinoa|rice|pasta|bread/i then :carbs
    when /cacahuète|peanut|oil|avocat/i then :fats
    when /chia|soja|soy|vinegar|sauce|mustard/i then :pantry
    else :other
    end
  end

  # MealTemplate has no :prep type — batch prep recipes log as dinner trays.
  def template_meal_type
    meal_type_prep? ? "dinner" : meal_type
  end
end
