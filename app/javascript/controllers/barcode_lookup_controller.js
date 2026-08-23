import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "status", "manualBarcode", "searchQuery", "results", "form", "name", "brand", "barcode",
    "calories", "protein", "carbs", "fat", "servingG", "servingLabel", "notes",
    "beverage", "waterVolumeMl"
  ]

  static values = {
    lookupUrl: String,
    searchUrl: String
  }

  connect() {
    this.manualBarcodeTarget?.addEventListener("keydown", this.onBarcodeKeydown)
    this.searchQueryTarget?.addEventListener("keydown", this.onSearchKeydown)
    this.toggleBeverageFields()
  }

  disconnect() {
    this.manualBarcodeTarget?.removeEventListener("keydown", this.onBarcodeKeydown)
    this.searchQueryTarget?.removeEventListener("keydown", this.onSearchKeydown)
  }

  onBarcodeKeydown = (event) => {
    if (event.key === "Enter") {
      event.preventDefault()
      this.lookupManual()
    }
  }

  onSearchKeydown = (event) => {
    if (event.key === "Enter") {
      event.preventDefault()
      this.searchByName()
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
    this.clearResults()
    this.setStatus("Looking up product…")
    const code = barcode.toString().replace(/\D/g, "")

    try {
      const data = await this.postJson(this.lookupUrlValue, { barcode: code })
      this.fillForm(data)
      if (this.hasManualBarcodeTarget) this.manualBarcodeTarget.value = code
      this.setStatus(`Found: ${data.name}`)
    } catch (error) {
      this.setStatus(error.message || "Product not found — enter details manually.")
    }
  }

  async searchByName() {
    const query = this.searchQueryTarget?.value?.trim() || ""
    if (query.length < 2) {
      this.setStatus("Type at least 2 characters to search.")
      return
    }

    this.clearResults()
    this.setStatus("Searching Open Food Facts…")

    try {
      const data = await this.postJson(this.searchUrlValue, { q: query })
      const products = data.products || []
      if (!products.length) {
        this.setStatus("No products found — try another name or enter details manually.")
        return
      }

      this.renderResults(products)
      this.setStatus(`${products.length} match${products.length === 1 ? "" : "es"} — tap one to fill the form.`)
    } catch (error) {
      this.setStatus(error.message || "Search failed — enter details manually.")
    }
  }

  chooseResult(event) {
    const button = event.currentTarget
    let product
    try {
      product = JSON.parse(button.dataset.product || "{}")
    } catch (_error) {
      this.setStatus("Could not read that result.")
      return
    }

    this.fillForm(product)
    this.clearResults()
    this.setStatus(`Selected: ${product.name}`)
  }

  renderResults(products) {
    if (!this.hasResultsTarget) return

    this.resultsTarget.innerHTML = products.map((product) => {
      const label = [ product.name, product.brand ].filter(Boolean).join(" · ")
      const meta = [
        product.calories_per_100g != null ? `${product.calories_per_100g} kcal/100 g` : null,
        product.barcode
      ].filter(Boolean).join(" · ")
      const payload = this.escapeAttr(JSON.stringify(product))

      return `<button type="button" class="list-group-item list-group-item-action py-2"
                data-action="barcode-lookup#chooseResult" data-product="${payload}">
                <span class="d-block fw-semibold">${this.escapeHtml(label)}</span>
                <span class="small text-muted">${this.escapeHtml(meta)}</span>
              </button>`
    }).join("")

    this.resultsTarget.classList.remove("d-none")
  }

  clearResults() {
    if (!this.hasResultsTarget) return
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("d-none")
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

  async postJson(url, params) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      credentials: "same-origin",
      body: new URLSearchParams(params)
    })

    let data = {}
    try {
      data = await response.json()
    } catch (_error) {
      throw new Error("Server returned an invalid response.")
    }

    if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`)
    return data
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
  }

  escapeAttr(value) {
    return this.escapeHtml(value).replaceAll("'", "&#39;")
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
