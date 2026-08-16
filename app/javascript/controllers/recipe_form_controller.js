import { Controller } from "@hotwired/stimulus"

// Live recipe totals from linked products × grams — no retyping nutrition.
export default class extends Controller {
  static targets = ["row", "product", "grams", "rowHint", "calories", "protein", "macrosHint", "serves"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    let calories = 0
    let protein = 0
    let carbs = 0
    let fat = 0
    let tracked = 0

    this.rowTargets.forEach((row) => {
      const product = row.querySelector("[data-recipe-form-target='product']")
      const gramsInput = row.querySelector("[data-recipe-form-target='grams']")
      const hint = row.querySelector("[data-recipe-form-target='rowHint']")
      const option = product?.selectedOptions?.[0]
      const grams = parseFloat(gramsInput?.value)

      if (!option?.value || !grams || grams <= 0) {
        if (hint) hint.textContent = ""
        return
      }

      const factor = grams / 100
      const rowCal = (parseFloat(option.dataset.calories) || 0) * factor
      const rowPro = (parseFloat(option.dataset.protein) || 0) * factor
      const rowCarb = (parseFloat(option.dataset.carbs) || 0) * factor
      const rowFat = (parseFloat(option.dataset.fat) || 0) * factor

      calories += rowCal
      protein += rowPro
      carbs += rowCarb
      fat += rowFat
      tracked += 1

      if (hint) {
        hint.textContent = `${Math.round(rowCal)} kcal · ${rowPro.toFixed(1)} g protein`
      }
    })

    const serves = Math.max(parseFloat(this.hasServesTarget ? this.servesTarget.value : 1) || 1, 1)
    const perCal = Math.round(calories / serves)
    const perPro = Math.round(protein / serves)

    if (this.hasCaloriesTarget) this.caloriesTarget.value = tracked > 0 ? perCal : ""
    if (this.hasProteinTarget) this.proteinTarget.value = tracked > 0 ? perPro : ""

    if (this.hasMacrosHintTarget) {
      this.macrosHintTarget.textContent = tracked > 0
        ? `From linked products: ~${Math.round(calories)} kcal · ${protein.toFixed(1)} g protein total` +
          (serves > 1 ? ` → ~${perCal} kcal · ${perPro} g protein per serving` : "")
        : "Link products + grams below to calculate nutrition automatically."
    }
  }

  productChanged(event) {
    const row = event.target.closest("[data-recipe-form-target='row']")
    const option = event.target.selectedOptions?.[0]
    if (!row || !option?.value) {
      this.recalculate()
      return
    }

    const nameField = row.querySelector("[data-recipe-form-target='name']")
    const amountField = row.querySelector("[data-recipe-form-target='amount']")
    const gramsField = row.querySelector("[data-recipe-form-target='grams']")
    const categoryField = row.querySelector("[data-recipe-form-target='category']")

    if (nameField && !nameField.value) nameField.value = option.dataset.name || option.textContent.trim()
    if (gramsField && !gramsField.value && option.dataset.servingG) {
      gramsField.value = option.dataset.servingG
    }
    if (amountField && !amountField.value && gramsField?.value) {
      amountField.value = `${gramsField.value} g`
    }
    if (categoryField && option.dataset.category) {
      categoryField.value = option.dataset.category
    }

    this.recalculate()
  }
}
