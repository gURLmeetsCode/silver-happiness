import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "product", "quantity", "name",
    "calories", "protein", "carbs", "fat",
    "previewCalories", "previewProtein", "previewRemainingProtein"
  ]

  static values = {
    currentCalories: Number,
    currentProtein: Number,
    proteinMin: Number,
    calorieTarget: Number
  }

  connect() {
    this.recalculate()
  }

  recalculate() {
    if (this.hasProductTarget && this.productTarget.value) {
      this.calculateFromProduct()
    } else if (this.hasCaloriesTarget) {
      this.updatePreview(
        parseFloat(this.caloriesTarget.value) || 0,
        parseFloat(this.proteinTarget.value) || 0
      )
    }
  }

  calculateFromProduct() {
    const option = this.productTarget.selectedOptions[0]
    if (!option) return

    const quantity = parseFloat(this.quantityTarget.value) || 0
    const factor = quantity / 100
    const calories = Math.round(parseFloat(option.dataset.calories) * factor)
    const protein = Math.round(parseFloat(option.dataset.protein) * factor * 10) / 10
    const carbs = Math.round(parseFloat(option.dataset.carbs) * factor * 10) / 10
    const fat = Math.round(parseFloat(option.dataset.fat) * factor * 10) / 10

    this.updatePreview(calories, protein)

    if (this.hasNameTarget && !this.nameTarget.value) {
      this.nameTarget.placeholder = `${quantity}g ${option.text.trim()}`
    }
  }

  updatePreview(addCalories, addProtein) {
    const totalCalories = this.currentCaloriesValue + addCalories
    const totalProtein = this.currentProteinValue + addProtein
    const remainingProtein = Math.max(0, this.proteinMinValue - totalProtein)

    if (this.hasPreviewCaloriesTarget) {
      this.previewCaloriesTarget.textContent = `${totalCalories} kcal eaten (${addCalories} this meal)`
    }
    if (this.hasPreviewProteinTarget) {
      this.previewProteinTarget.textContent = `${totalProtein.toFixed(0)} g protein`
    }
    if (this.hasPreviewRemainingProteinTarget) {
      this.previewRemainingProteinTarget.textContent =
        remainingProtein > 0 ? `${remainingProtein.toFixed(0)} g protein left to min goal` : "Protein min goal met"
    }
  }
}
