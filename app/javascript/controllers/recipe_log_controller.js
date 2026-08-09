import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calories", "protein", "carbs", "fat", "notes", "servings",
    "ingredientRow", "ingredientInclude", "ingredientGrams",
    "extraProduct", "extraQuantity", "extraUnit", "extraHint", "extraRow",
    "preview"
  ]

  static values = {
    baseCalories: Number,
    baseProtein: Number,
    baseCarbs: Number,
    baseFat: Number,
    serves: Number,
    skipInitialRecalc: Boolean
  }

  connect() {
    this.extraRowTargets.forEach((row) => this.updateExtraHint(row))
    this.ingredientRowTargets.forEach((row) => this.updateIngredientRow(row))

    // Reopening a saved meal must not silently rewrite the numbers that were
    // logged, so only recalculate once the user touches something.
    if (!this.skipInitialRecalcValue) this.recalculate()
    else if (this.hasPreviewTarget && this.hasCaloriesTarget) {
      this.previewTarget.textContent = `${this.caloriesTarget.value} kcal logged — change anything to recalculate`
    }
  }

  productChanged(event) {
    const row = event.target.closest("[data-recipe-log-target='extraRow']")
    if (row) this.updateExtraHint(row)
    this.recalculate()
  }

  updateExtraHint(row) {
    const product = row.querySelector("[data-recipe-log-target='extraProduct']")
    const hint = row.querySelector("[data-recipe-log-target='extraHint']")
    const unit = row.querySelector("[data-recipe-log-target='extraUnit']")
    if (!product?.value || !hint) {
      if (hint) hint.textContent = ""
      return
    }

    const option = product.selectedOptions[0]
    const servingG = parseFloat(option.dataset.servingG) || 15
    const servingLabel = option.dataset.servingLabel || "1 tbsp"
    if (unit?.value === "tbsp") {
      hint.textContent = `= ${servingG} g/${servingLabel.replace(/^1\s+/, "")}`
    } else {
      hint.textContent = "grams"
    }
  }

  // Grey out and disable the amount of an ingredient that was left out.
  updateIngredientRow(row) {
    const include = row.querySelector("[data-recipe-log-target='ingredientInclude']")
    const grams = row.querySelector("[data-recipe-log-target='ingredientGrams']")
    if (!include || !grams) return

    grams.disabled = !include.checked
    row.classList.toggle("is-excluded", !include.checked)
  }

  // Per-serving nutrition from the ingredients as they are actually ticked and
  // sized. Falls back to the recipe's stored figures when a recipe has no
  // product-linked ingredients to add up.
  basePerServing() {
    if (this.ingredientRowTargets.length === 0) {
      return {
        calories: this.baseCaloriesValue || 0,
        protein: this.baseProteinValue || 0,
        carbs: this.baseCarbsValue || 0,
        fat: this.baseFatValue || 0
      }
    }

    const totals = { calories: 0, protein: 0, carbs: 0, fat: 0 }

    this.ingredientRowTargets.forEach((row) => {
      this.updateIngredientRow(row)

      const include = row.querySelector("[data-recipe-log-target='ingredientInclude']")
      const grams = row.querySelector("[data-recipe-log-target='ingredientGrams']")
      if (!grams || (include && !include.checked)) return

      const amount = parseFloat(grams.value) || 0
      if (amount <= 0) return

      const factor = amount / 100
      totals.calories += (parseFloat(grams.dataset.calories) || 0) * factor
      totals.protein += (parseFloat(grams.dataset.protein) || 0) * factor
      totals.carbs += (parseFloat(grams.dataset.carbs) || 0) * factor
      totals.fat += (parseFloat(grams.dataset.fat) || 0) * factor
    })

    const serves = Math.max(this.servesValue || 1, 1)
    return {
      calories: totals.calories / serves,
      protein: totals.protein / serves,
      carbs: totals.carbs / serves,
      fat: totals.fat / serves
    }
  }

  recalculate() {
    const servings = this.hasServingsTarget ? Math.max(parseFloat(this.servingsTarget.value) || 1, 1) : 1
    const base = this.basePerServing()

    let calories = base.calories * servings
    let protein = base.protein * servings
    let carbs = base.carbs * servings
    let fat = base.fat * servings

    this.extraRowTargets.forEach((row) => {
      const product = row.querySelector("[data-recipe-log-target='extraProduct']")
      const quantity = row.querySelector("[data-recipe-log-target='extraQuantity']")
      const unit = row.querySelector("[data-recipe-log-target='extraUnit']")
      if (!product?.value || !quantity?.value) return

      const option = product.selectedOptions[0]
      const qty = parseFloat(quantity.value) || 0
      const grams = unit?.value === "tbsp"
        ? qty * (parseFloat(option.dataset.servingG) || 15)
        : qty
      const factor = grams / 100

      calories += Math.round(parseFloat(option.dataset.calories) * factor)
      protein += Math.round(parseFloat(option.dataset.protein) * factor * 10) / 10
      carbs += Math.round(parseFloat(option.dataset.carbs) * factor * 10) / 10
      fat += Math.round(parseFloat(option.dataset.fat) * factor * 10) / 10

      this.updateExtraHint(row)
    })

    if (this.hasCaloriesTarget) this.caloriesTarget.value = Math.round(calories)
    if (this.hasProteinTarget) this.proteinTarget.value = Math.round(protein * 10) / 10
    if (this.hasCarbsTarget) this.carbsTarget.value = Math.round(carbs * 10) / 10
    if (this.hasFatTarget) this.fatTarget.value = Math.round(fat * 10) / 10

    if (this.hasPreviewTarget) {
      const servingLabel = servings === 1 ? "1 serving" : `${servings} servings`
      this.previewTarget.textContent = `${Math.round(calories)} kcal · ${protein.toFixed(1)} g protein · ${carbs.toFixed(1)} g carbs · ${fat.toFixed(1)} g fat (${servingLabel})`
    }
  }
}
