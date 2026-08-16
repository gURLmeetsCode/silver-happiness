import { Controller } from "@hotwired/stimulus"

const ML_PER_UNIT = { tsp: 5, tbsp: 15, cup: 240, ml: 1 }

const VULGAR_FRACTIONS = {
  "½": 0.5, "⅓": 1 / 3, "⅔": 2 / 3, "¼": 0.25, "¾": 0.75,
  "⅕": 0.2, "⅖": 0.4, "⅗": 0.6, "⅘": 0.8, "⅙": 1 / 6, "⅛": 0.125
}

// Assembles one meal from several products. Amounts are whatever suits the
// item — half a cup, a teaspoon, half a pack — and the totals add themselves up.
export default class extends Controller {
  static targets = ["rows", "row", "template", "product", "quantity", "unit", "hint", "total", "name"]

  connect() {
    this.nextIndex = this.rowTargets.length
    this.rowTargets.forEach((row) => this.refreshUnits(row))
    this.recalculate()
  }

  addRow() {
    const markup = this.templateTarget.innerHTML.replaceAll("__INDEX__", this.nextIndex)
    this.nextIndex += 1
    this.rowsTarget.insertAdjacentHTML("beforeend", markup)
    this.recalculate()
  }

  removeRow(event) {
    const row = event.currentTarget.closest("[data-meal-builder-target='row']")
    if (!row) return

    // Keep one row so the form is never empty and unusable.
    if (this.rowTargets.length > 1) row.remove()
    else this.clearRow(row)

    this.recalculate()
  }

  clearRow(row) {
    const product = row.querySelector("[data-meal-builder-target='product']")
    const quantity = row.querySelector("[data-meal-builder-target='quantity']")
    if (product) {
      product.value = ""
      product.dispatchEvent(new Event("change", { bubbles: true }))
    }
    if (quantity) quantity.value = ""
    this.refreshUnits(row)
  }

  productChanged(event) {
    const row = event.target.closest("[data-meal-builder-target='row']")
    if (!row) return

    const product = row.querySelector("[data-meal-builder-target='product']")
    const quantity = row.querySelector("[data-meal-builder-target='quantity']")
    const option = product?.selectedOptions?.[0]
    this.refreshUnits(row)

    // Batches default to a plate share; recipes/products default to one serving.
    if (option?.dataset?.kind === "template" && quantity && !quantity.value) {
      quantity.value = option.dataset.batch === "true" ? "0.25" : "1"
    } else if (option?.value && option.dataset.kind !== "template" && quantity && !quantity.value) {
      quantity.value = option.dataset.servingG || "100"
    }

    this.recalculate()
  }

  // Offer the units that make sense for this item, its own serving first, so
  // "half a pavé of tofu" is 0.5 rather than 62.5 g.
  refreshUnits(row) {
    const product = row.querySelector("[data-meal-builder-target='product']")
    const unit = row.querySelector("[data-meal-builder-target='unit']")
    if (!product || !unit) return

    const option = product.selectedOptions[0]
    const units = this.parseUnits(option)
    const previous = unit.value

    unit.innerHTML = units
      .map(([label, value]) => `<option value="${value}">${label}</option>`)
      .join("")

    if (units.some(([, value]) => value === previous)) unit.value = previous
  }

  parseUnits(option) {
    if (!option?.dataset?.units) return [["g", "g"]]

    try {
      return JSON.parse(option.dataset.units)
    } catch {
      return [["g", "g"]]
    }
  }

  // "½", "1/2", "1 1/2" and "0.5" all mean the same thing to a person.
  parseQuantity(raw) {
    if (!raw) return 0

    const text = raw.trim().replace(",", ".")
    let total = 0
    let matched = false

    for (const [glyph, value] of Object.entries(VULGAR_FRACTIONS)) {
      if (text.includes(glyph)) {
        total += value
        matched = true
      }
    }

    const stripped = text.replace(new RegExp(`[${Object.keys(VULGAR_FRACTIONS).join("")}]`, "g"), " ").trim()

    const mixed = stripped.match(/^(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)$/)
    if (mixed) return total + parseFloat(mixed[1]) + parseFloat(mixed[2]) / parseFloat(mixed[3])

    const fraction = stripped.match(/^(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)$/)
    if (fraction) return total + parseFloat(fraction[1]) / parseFloat(fraction[2])

    const decimal = parseFloat(stripped)
    if (!Number.isNaN(decimal)) return total + decimal

    return matched ? total : 0
  }

  gramsFor(option, quantity, unit) {
    if (option?.dataset?.kind === "template") {
      // Templates use "serving" as a fraction of the full batch. Hint shows a
      // synthetic "grams" scale so the live total still feels tangible.
      return quantity * 100
    }
    if (unit === "serving") return quantity * (parseFloat(option.dataset.servingG) || 100)
    if (unit === "g" || !unit) return quantity

    const gramsPerMl = parseFloat(option.dataset.gramsPerMl) || 1
    return quantity * (ML_PER_UNIT[unit] || 1) * gramsPerMl
  }

  recalculate() {
    const totals = { calories: 0, protein: 0, carbs: 0, fat: 0 }
    const names = []

    this.rowTargets.forEach((row) => {
      const product = row.querySelector("[data-meal-builder-target='product']")
      const quantity = row.querySelector("[data-meal-builder-target='quantity']")
      const unit = row.querySelector("[data-meal-builder-target='unit']")
      const hint = row.querySelector("[data-meal-builder-target='hint']")

      if (!product?.value) {
        if (hint) hint.textContent = ""
        return
      }

      const option = product.selectedOptions[0]
      const amount = this.parseQuantity(quantity?.value)
      if (amount <= 0) {
        if (hint) hint.textContent = ""
        return
      }

      const kind = option.dataset.kind || "product"
      let calories, protein, carbs, fat, hintText

      if (kind === "template") {
        // Option datasets are totals for 1× the full recipe/batch.
        calories = (parseFloat(option.dataset.calories) || 0) * amount
        protein = (parseFloat(option.dataset.protein) || 0) * amount
        carbs = (parseFloat(option.dataset.carbs) || 0) * amount
        fat = (parseFloat(option.dataset.fat) || 0) * amount
        const scaleLabel = option.dataset.batch === "true" ? "batch" : "recipe"
        hintText = `${amount}× ${scaleLabel} · ${Math.round(calories)} kcal`
      } else {
        const grams = this.gramsFor(option, amount, unit?.value)
        const factor = grams / 100
        calories = (parseFloat(option.dataset.calories) || 0) * factor
        protein = (parseFloat(option.dataset.protein) || 0) * factor
        carbs = (parseFloat(option.dataset.carbs) || 0) * factor
        fat = (parseFloat(option.dataset.fat) || 0) * factor
        hintText = `${Math.round(grams)} g · ${Math.round(calories)} kcal`
      }

      totals.calories += calories
      totals.protein += protein
      totals.carbs += carbs
      totals.fat += fat
      names.push(option.textContent.trim().replace(/\s*\(\d+ kcal full\)\s*$/, ""))

      if (hint) hint.textContent = hintText
    })

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = names.length === 0
        ? "Nothing added yet"
        : `${Math.round(totals.calories)} kcal · ${totals.protein.toFixed(1)} g protein · ${totals.carbs.toFixed(1)} g carbs · ${totals.fat.toFixed(1)} g fat`
    }

    if (this.hasNameTarget && names.length > 0) {
      this.nameTarget.placeholder = names.slice(0, 2).join(", ") +
        (names.length > 2 ? ` + ${names.length - 2} more` : "")
    }
  }
}
