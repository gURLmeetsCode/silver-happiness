class RecipeIngredient < ApplicationRecord
  enum :grocery_category, {
    produce: 0,
    protein: 1,
    carbs: 2,
    pantry: 3,
    fats: 4,
    other: 5
  }, prefix: :category

  belongs_to :recipe
  belongs_to :product, optional: true

  validates :name, presence: true
  validates :quantity_g, numericality: { greater_than: 0 }, allow_nil: true
  validate :quantity_required_with_product

  before_validation :apply_product_defaults

  after_save :sync_recipe_macros
  after_destroy :sync_recipe_macros

  CATEGORY_LABELS = {
    "produce" => "Produce & veg",
    "protein" => "Protein",
    "carbs" => "Carbs & grains",
    "pantry" => "Pantry & condiments",
    "fats" => "Fats & nuts",
    "other" => "Other"
  }.freeze

  def category_label
    CATEGORY_LABELS[grocery_category] || grocery_category.humanize
  end

  def tracked?
    product.present? && quantity_g.to_f.positive?
  end

  def nutrition
    return nil unless tracked?

    product.nutrition_for(quantity_g)
  end

  def display
    label = product.present? ? product.name : name
    [ amount, label ].compact_blank.join(" ")
  end

  def display_with_nutrition
    base = display
    n = nutrition
    return base unless n

    "#{base} · #{n[:calories]} kcal · #{n[:protein]}g protein"
  end

  private

  def apply_product_defaults
    return unless product

    self.name = product.name if name.blank?
    self.amount = "#{quantity_g.to_i} g" if amount.blank? && quantity_g.present?
  end

  def quantity_required_with_product
    return unless product_id.present?
    return if quantity_g.to_f.positive?

    errors.add(:quantity_g, "is required when using a saved product")
  end

  def sync_recipe_macros
    recipe.sync_macros_from_ingredients!
  end
end
