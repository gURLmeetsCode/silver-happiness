import { Controller } from "@hotwired/stimulus"

// Turns a long <select> into a type-to-filter combobox while keeping the
// native select in the form (so Rails params stay unchanged).
export default class extends Controller {
  static targets = ["select", "input", "menu"]

  connect() {
    if (!this.hasSelectTarget) return
    if (this.hasInputTarget) {
      this.syncFromSelect()
      return
    }

    this.buildUi()
    this.syncFromSelect()
    this.boundOutside = (event) => this.closeIfOutside(event)
    this.boundSelectChange = () => this.syncFromSelect()
    document.addEventListener("click", this.boundOutside)
    this.selectTarget.addEventListener("change", this.boundSelectChange)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutside)
    if (this.hasSelectTarget && this.boundSelectChange) {
      this.selectTarget.removeEventListener("change", this.boundSelectChange)
    }
  }

  buildUi() {
    this.selectTarget.classList.add("searchable-select-native")
    this.selectTarget.setAttribute("tabindex", "-1")
    this.selectTarget.setAttribute("aria-hidden", "true")

    const input = document.createElement("input")
    input.type = "search"
    input.className = "form-control form-control-sm searchable-select-input"
    input.autocomplete = "off"
    input.spellcheck = false
    input.placeholder = this.selectTarget.dataset.searchPlaceholder || "Search…"
    input.setAttribute("data-searchable-select-target", "input")
    input.setAttribute("data-action", [
      "input->searchable-select#filter",
      "focus->searchable-select#open",
      "keydown->searchable-select#keydown"
    ].join(" "))
    input.setAttribute("aria-label", this.selectTarget.getAttribute("aria-label") || "Search")

    const menu = document.createElement("div")
    menu.className = "searchable-select-menu d-none"
    menu.setAttribute("data-searchable-select-target", "menu")
    menu.setAttribute("role", "listbox")

    this.element.classList.add("searchable-select")
    this.selectTarget.insertAdjacentElement("afterend", input)
    input.insertAdjacentElement("afterend", menu)
  }

  open() {
    this.renderMenu(this.inputTarget.value)
    this.menuTarget.classList.remove("d-none")
  }

  close() {
    if (this.hasMenuTarget) this.menuTarget.classList.add("d-none")
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  filter() {
    this.open()
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.syncFromSelect()
      this.inputTarget.blur()
    }
  }

  choose(event) {
    const value = event.currentTarget.dataset.value
    this.selectTarget.value = value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.syncFromSelect()
    this.close()
  }

  syncFromSelect() {
    if (!this.hasInputTarget) return
    const option = this.selectTarget.selectedOptions[0]
    this.inputTarget.value = option && option.value ? option.textContent.trim() : ""
  }

  renderMenu(query) {
    const q = (query || "").trim().toLowerCase()
    const fragments = []
    let groupLabel = null
    let matches = 0

    Array.from(this.selectTarget.options).forEach((option) => {
      if (option.parentElement?.tagName === "OPTGROUP") {
        const nextGroup = option.parentElement.label
        if (nextGroup !== groupLabel) {
          groupLabel = nextGroup
        }
      } else {
        groupLabel = null
      }

      if (!option.value) return
      const text = option.textContent.trim()
      if (q && !text.toLowerCase().includes(q) && !(groupLabel || "").toLowerCase().includes(q)) {
        return
      }

      if (groupLabel && fragments[fragments.length - 1]?.group !== groupLabel) {
        fragments.push({ group: groupLabel, html: `<div class="searchable-select-group">${this.escape(groupLabel)}</div>` })
      }

      const selected = option.value === this.selectTarget.value
      fragments.push({
        group: groupLabel,
        html: `<button type="button" class="searchable-select-option${selected ? " is-selected" : ""}"
                  data-action="searchable-select#choose" data-value="${this.escapeAttr(option.value)}" role="option">
                  ${this.escape(text)}
                </button>`
      })
      matches += 1
    })

    if (matches === 0) {
      this.menuTarget.innerHTML = `<div class="searchable-select-empty">No matches</div>`
      return
    }

    this.menuTarget.innerHTML = fragments.map((f) => f.html).join("")
  }

  escape(text) {
    return text
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
  }

  escapeAttr(text) {
    return this.escape(String(text)).replaceAll("'", "&#39;")
  }
}
