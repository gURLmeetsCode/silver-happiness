import { Controller } from "@hotwired/stimulus"

// Client-side filter for recipe cards on the recipes index.
export default class extends Controller {
  static targets = ["input", "card", "empty"]

  filter() {
    const q = this.inputTarget.value.trim().toLowerCase()
    let visible = 0

    this.cardTargets.forEach((card) => {
      const haystack = (card.dataset.searchText || card.textContent || "").toLowerCase()
      const show = !q || haystack.includes(q)
      card.classList.toggle("d-none", !show)
      if (show) visible += 1
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("d-none", visible > 0 || !q)
    }
  }
}
