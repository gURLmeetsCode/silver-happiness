import { Controller } from "@hotwired/stimulus"

// Keeps the day log's tabs addressable. Links from the home screen point at
// #meals or #beverages, so the hash has to select the right tab and then
// scroll to the card inside it.
export default class extends Controller {
  static values = { cardTabs: Object }

  connect() {
    this.showFromHash()
    this.hashListener = () => this.showFromHash()
    window.addEventListener("hashchange", this.hashListener)
  }

  disconnect() {
    window.removeEventListener("hashchange", this.hashListener)
  }

  showFromHash() {
    const hash = window.location.hash.replace("#", "")
    if (!hash) return

    const tabName = this.cardTabsValue[hash] || hash
    const trigger = this.element.querySelector(`[data-tab-name="${tabName}"]`)
    if (!trigger) return

    // eslint-disable-next-line no-undef
    bootstrap.Tab.getOrCreateInstance(trigger).show()

    if (tabName !== hash) {
      requestAnimationFrame(() => {
        document.getElementById(hash)?.scrollIntoView({ behavior: "smooth", block: "start" })
      })
    }
  }

  // Reflect the active tab in the URL so a refresh or back button stays put.
  select(event) {
    const tabName = event.currentTarget.dataset.tabName
    if (tabName) history.replaceState(null, "", `#${tabName}`)
  }
}
