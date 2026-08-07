import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calories", "protein", "carbs", "fat", "notes",
    "extraProduct", "extraQuantity", "extraRow",
    "preview"
  ]

  static values = {
    baseCalories: Number,
    baseProtein: Number,
    baseCarbs: Number,
    baseFat: Number
  }

  connect() {
    this.recalculate()
  }

  recalculate() {
    let calories = this.baseCaloriesValue || 0
    let protein = this.baseProteinValue || 0
    let carbs = this.baseCarbsValue || 0
    let fat = this.baseFatValue || 0

    this.extraRowTargets.forEach((row) => {
      const product = row.querySelector("[data-recipe-log-target='extraProduct']")
      const quantity = row.querySelector("[data-recipe-log-target='extraQuantity']")
      if (!product?.value || !quantity?.value) return

      const option = product.selectedOptions[0]
      const qty = parseFloat(quantity.value) || 0
      const factor = qty / 100

      calories += Math.round(parseFloat(option.dataset.calories) * factor)
      protein += Math.round(parseFloat(option.dataset.protein) * factor * 10) / 10
      carbs += Math.round(parseFloat(option.dataset.carbs) * factor * 10) / 10
      fat += Math.round(parseFloat(option.dataset.fat) * factor * 10) / 10
    })

    if (this.hasCaloriesTarget) this.caloriesTarget.value = calories
    if (this.hasProteinTarget) this.proteinTarget.value = protein
    if (this.hasCarbsTarget) this.carbsTarget.value = carbs
    if (this.hasFatTarget) this.fatTarget.value = fat

    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = `${calories} kcal · ${protein.toFixed(1)} g protein · ${carbs.toFixed(1)} g carbs · ${fat.toFixed(1)} g fat`
    }
  }
}
