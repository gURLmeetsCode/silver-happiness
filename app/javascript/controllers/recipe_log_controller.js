import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calories", "protein", "carbs", "fat", "notes", "servings",
    "extraProduct", "extraQuantity", "extraUnit", "extraHint", "extraRow",
    "preview"
  ]

  static values = {
    baseCalories: Number,
    baseProtein: Number,
    baseCarbs: Number,
    baseFat: Number,
    skipInitialRecalc: Boolean
  }

  connect() {
    this.extraRowTargets.forEach((row) => this.updateExtraHint(row))
    if (!this.skipInitialRecalcValue) this.recalculate()
    else if (this.hasPreviewTarget && this.hasCaloriesTarget) {
      this.previewTarget.textContent = `${this.caloriesTarget.value} kcal logged — change servings or extras to recalculate`
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

  recalculate() {
    const servings = this.hasServingsTarget ? Math.max(parseFloat(this.servingsTarget.value) || 1, 1) : 1
    let calories = (this.baseCaloriesValue || 0) * servings
    let protein = (this.baseProteinValue || 0) * servings
    let carbs = (this.baseCarbsValue || 0) * servings
    let fat = (this.baseFatValue || 0) * servings

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
