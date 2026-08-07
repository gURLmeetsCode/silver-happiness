import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox", "progress" ]
  static values = {
    toggleUrl: String,
    total: Number,
    checked: Number
  }

  async toggle(event) {
    const checkbox = event.currentTarget
    const itemKey = checkbox.dataset.itemKey
    const label = checkbox.closest(".grocery-item")

    try {
      const response = await fetch(this.toggleUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        body: new URLSearchParams({ item_key: itemKey })
      })

      if (!response.ok) throw new Error("Toggle failed")

      const data = await response.json()
      checkbox.checked = data.checked
      this.updateRow(label, data.checked)
      this.updateProgress(data.checked)
    } catch (_error) {
      checkbox.checked = !checkbox.checked
    }
  }

  updateRow(label, checked) {
    if (!label) return

    label.classList.toggle("grocery-item--checked", checked)
    const text = label.querySelector(".grocery-item__label")
    if (text) {
      text.classList.toggle("text-decoration-line-through", checked)
      text.classList.toggle("text-muted", checked)
    }
  }

  updateProgress(checked) {
    if (checked) {
      this.checkedValue += 1
    } else {
      this.checkedValue = Math.max(0, this.checkedValue - 1)
    }

    if (this.hasProgressTarget) {
      this.progressTarget.textContent = `${this.checkedValue} / ${this.totalValue} in cart`
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
