import { Controller } from "@hotwired/stimulus"

const LIBRARY_URL = "/javascript/html5-qrcode.min.js"

export default class extends Controller {
  static targets = [
    "reader", "status", "manualBarcode", "form", "name", "brand", "barcode",
    "calories", "protein", "carbs", "fat", "servingG", "servingLabel", "notes"
  ]

  static values = {
    lookupUrl: String
  }

  connect() {
    this.scanner = null
    this.scanning = false
    if (this.hasReaderTarget && !this.readerTarget.id) {
      this.readerTarget.id = "barcode-reader"
    }
    this.manualBarcodeTarget?.addEventListener("keydown", this.onManualKeydown)
  }

  disconnect() {
    this.stopScan()
    this.manualBarcodeTarget?.removeEventListener("keydown", this.onManualKeydown)
  }

  onManualKeydown = (event) => {
    if (event.key === "Enter") {
      event.preventDefault()
      this.lookupManual()
    }
  }

  async startScan() {
    if (this.scanning) return

    this.setStatus("Loading scanner…")
    this.readerTarget.classList.remove("d-none")
    this.readerTarget.innerHTML = ""

    try {
      await this.ensureLibrary()
      await this.startHtml5Scan()
    } catch (error) {
      this.setStatus(`${error.message} — type the barcode below and tap Look up.`)
      this.stopScan()
    }
  }

  stopScan() {
    this.scanning = false
    if (this.scanner?.isScanning) {
      this.scanner.stop().catch(() => {})
    }
    this.scanner = null
    if (this.readerTarget) {
      this.readerTarget.innerHTML = ""
      this.readerTarget.classList.add("d-none")
    }
  }

  async ensureLibrary() {
    if (window.__Html5QrcodeLibrary__) return

    await new Promise((resolve, reject) => {
      const existing = document.querySelector(`script[src="${LIBRARY_URL}"]`)
      if (existing) {
        if (window.__Html5QrcodeLibrary__) {
          resolve()
          return
        }
        existing.addEventListener("load", resolve, { once: true })
        existing.addEventListener("error", () => reject(new Error("Scanner failed to load")), { once: true })
        return
      }

      const script = document.createElement("script")
      script.src = LIBRARY_URL
      script.async = true
      script.onload = resolve
      script.onerror = () => reject(new Error("Scanner failed to load"))
      document.head.appendChild(script)
    })

    if (!window.__Html5QrcodeLibrary__) {
      throw new Error("Scanner failed to load")
    }
  }

  async cameraConfig() {
    const { Html5Qrcode } = window.__Html5QrcodeLibrary__

    try {
      const cameras = await Html5Qrcode.getCameras()
      if (cameras?.length) {
        const back = cameras.find((camera) => /back|rear|environment|arrière/i.test(camera.label))
        const chosen = back || cameras[cameras.length - 1]
        return chosen.id
      }
    } catch (_error) {
      // getCameras can fail before permission — fall back to facingMode
    }

    return { facingMode: "environment" }
  }

  async startHtml5Scan() {
    const { Html5Qrcode, Html5QrcodeSupportedFormats: F } = window.__Html5QrcodeLibrary__
    this.scanner = new Html5Qrcode(this.readerTarget.id)
    this.scanning = true
    this.setStatus("Point at the barcode. Allow camera access if asked.")

    const formats = [ F.EAN_13, F.EAN_8, F.UPC_A, F.UPC_E, F.CODE_128 ].filter(Boolean)
    const camera = await this.cameraConfig()

    await this.scanner.start(
      camera,
      {
        fps: 10,
        qrbox: (viewfinderWidth, viewfinderHeight) => {
          const width = Math.min(viewfinderWidth * 0.92, 320)
          const height = Math.min(viewfinderHeight * 0.45, 180)
          return { width: Math.floor(width), height: Math.floor(height) }
        },
        formatsToSupport: formats.length ? formats : undefined,
        disableFlip: false,
        aspectRatio: 1.777778
      },
      async (decoded) => {
        this.stopScan()
        await this.lookup(decoded)
      },
      () => {}
    )
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

    let filled = 0
    fields.forEach(([ target, value ]) => {
      const el = this[`${target}Target`]
      if (!el || value == null || value === "") return

      el.value = value
      el.dispatchEvent(new Event("input", { bubbles: true }))
      filled += 1
    })

    if (filled > 0 && this.hasNameTarget) {
      this.nameTarget.scrollIntoView({ behavior: "smooth", block: "center" })
      this.nameTarget.focus({ preventScroll: true })
    }
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
