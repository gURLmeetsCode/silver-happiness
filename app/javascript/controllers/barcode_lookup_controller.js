import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "status", "manualBarcode", "form", "name", "brand", "barcode",
    "calories", "protein", "carbs", "fat", "servingG", "servingLabel", "notes",
    "beverage", "waterVolumeMl"
  ]

  static values = {
    lookupUrl: String
  }

  connect() {
    this.manualBarcodeTarget?.addEventListener("keydown", this.onManualKeydown)
    this.toggleBeverageFields()
  }

  disconnect() {
    this.manualBarcodeTarget?.removeEventListener("keydown", this.onManualKeydown)
  }

  onManualKeydown = (event) => {
    if (event.key === "Enter") {
      event.preventDefault()
      this.lookupManual()
    }
  }

  beverageChanged() {
    this.toggleBeverageFields()
  }

  toggleBeverageFields() {
    if (!this.hasBeverageTarget || !this.hasWaterVolumeMlTarget) return

    const show = this.beverageTarget.checked
    this.waterVolumeMlTarget.closest("[data-barcode-lookup-beverage-field]")?.classList.toggle("d-none", !show)
  }

  async lookupManual() {
    const code = this.manualBarcodeTarget.value.trim().replace(/\D/g, "")
    if (code.length < 8) {
      this.setStatus("Enter at least 8 digits from the barcode.")
      return
    }
    await this.lookup(code)
  }

  async lookup(barcode) {
    this.setStatus("Looking up product…")
    const code = barcode.toString().replace(/\D/g, "")

    try {
      const response = await fetch(this.lookupUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        credentials: "same-origin",
        body: new URLSearchParams({ barcode: code })
      })

      let data = {}
      try {
        data = await response.json()
      } catch (_error) {
        throw new Error("Server returned an invalid response.")
      }

      if (!response.ok) throw new Error(data.error || `Lookup failed (${response.status})`)

      this.fillForm(data)
      if (this.hasManualBarcodeTarget) this.manualBarcodeTarget.value = code
      this.setStatus(`Found: ${data.name}`)
    } catch (error) {
      this.setStatus(error.message || "Product not found — enter details manually.")
    }
  }

  fillForm(data) {
    const fields = [
      [ "name", data.name ],
      [ "brand", data.brand ],
      [ "barcode", data.barcode ],
      [ "calories", data.calories_per_100g ],
      [ "protein", data.protein_per_100g ],
      [ "carbs", data.carbs_per_100g ],
      [ "fat", data.fat_per_100g ],
      [ "servingG", data.default_serving_g ],
      [ "servingLabel", data.serving_label ],
      [ "notes", data.notes ]
    ]

    fields.forEach(([ target, value ]) => {
      const el = this[`${target}Target`]
      if (!el || value == null || value === "") return
      el.value = value
      el.dispatchEvent(new Event("input", { bubbles: true }))
    })

    if (this.hasNameTarget) {
      this.nameTarget.scrollIntoView({ behavior: "smooth", block: "center" })
      this.nameTarget.focus({ preventScroll: true })
    }
  }

  validateForm(event) {
    if (!this.hasFormTarget) return

    if (!this.formTarget.checkValidity()) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.formTarget.classList.add("was-validated")
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
