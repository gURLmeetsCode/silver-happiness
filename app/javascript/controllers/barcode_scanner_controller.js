import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "reader", "status", "manualBarcode", "name", "brand", "barcode",
    "calories", "protein", "carbs", "fat", "servingG", "servingLabel", "notes"
  ]

  static values = {
    lookupUrl: String
  }

  connect() {
    this.scanner = null
    this.scanning = false
  }

  disconnect() {
    this.stopScan()
  }

  async startScan() {
    if (this.scanning) return

    this.setStatus("Starting camera…")
    this.readerTarget.classList.remove("d-none")

    if ("BarcodeDetector" in window) {
      await this.startNativeScan()
    } else {
      await this.startLibraryScan()
    }
  }

  stopScan() {
    this.scanning = false
    if (this.scanner?.stop) {
      this.scanner.stop().catch(() => {})
      this.scanner = null
    }
    if (this.nativeStream) {
      this.nativeStream.getTracks().forEach((track) => track.stop())
      this.nativeStream = null
    }
    if (this.nativeInterval) {
      clearInterval(this.nativeInterval)
      this.nativeInterval = null
    }
    this.readerTarget.innerHTML = ""
    this.readerTarget.classList.add("d-none")
    this.setStatus("")
  }

  async startNativeScan() {
    try {
      this.nativeStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" },
        audio: false
      })

      const video = document.createElement("video")
      video.setAttribute("playsinline", true)
      video.srcObject = this.nativeStream
      await video.play()
      this.readerTarget.appendChild(video)

      const detector = new BarcodeDetector({ formats: [ "ean_13", "ean_8", "upc_a", "upc_e" ] })
      this.scanning = true
      this.setStatus("Point at the barcode on the package")

      this.nativeInterval = setInterval(async () => {
        if (!this.scanning) return
        try {
          const codes = await detector.detect(video)
          if (codes.length > 0) {
            this.stopScan()
            await this.lookup(codes[0].rawValue)
          }
        } catch (_error) {
          // keep scanning
        }
      }, 400)
    } catch (_error) {
      this.setStatus("Camera blocked — enter barcode manually below")
      this.stopScan()
    }
  }

  async startLibraryScan() {
    try {
      const { Html5Qrcode } = await import("https://cdn.jsdelivr.net/npm/html5-qrcode@2.3.8/+esm")
      this.scanner = new Html5Qrcode(this.readerTarget.id)
      this.scanning = true
      this.setStatus("Point at the barcode on the package")

      await this.scanner.start(
        { facingMode: "environment" },
        { fps: 8, qrbox: { width: 260, height: 160 } },
        async (decoded) => {
          this.stopScan()
          await this.lookup(decoded)
        },
        () => {}
      )
    } catch (_error) {
      this.setStatus("Scanner unavailable — enter barcode manually below")
      this.stopScan()
    }
  }

  async lookupManual() {
    const code = this.manualBarcodeTarget.value.trim()
    if (!code) return
    await this.lookup(code)
  }

  async lookup(barcode) {
    this.setStatus("Looking up product…")

    try {
      const response = await fetch(`${this.lookupUrlValue}?barcode=${encodeURIComponent(barcode)}`, {
        headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfToken }
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Not found")

      this.fillForm(data)
      this.setStatus(`Found: ${data.name}`)
    } catch (error) {
      this.setStatus(error.message || "Product not found — enter details manually")
    }
  }

  fillForm(data) {
    if (this.hasNameTarget && data.name) this.nameTarget.value = data.name
    if (this.hasBrandTarget && data.brand) this.brandTarget.value = data.brand
    if (this.hasBarcodeTarget && data.barcode) this.barcodeTarget.value = data.barcode
    if (this.hasCaloriesTarget && data.calories_per_100g != null) this.caloriesTarget.value = data.calories_per_100g
    if (this.hasProteinTarget && data.protein_per_100g != null) this.proteinTarget.value = data.protein_per_100g
    if (this.hasCarbsTarget && data.carbs_per_100g != null) this.carbsTarget.value = data.carbs_per_100g
    if (this.hasFatTarget && data.fat_per_100g != null) this.fatTarget.value = data.fat_per_100g
    if (this.hasServingGTarget && data.default_serving_g != null) this.servingGTarget.value = data.default_serving_g
    if (this.hasServingLabelTarget && data.serving_label) this.servingLabelTarget.value = data.serving_label
    if (this.hasNotesTarget && data.notes) this.notesTarget.value = data.notes
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
