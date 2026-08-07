import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  append(event) {
    event.preventDefault()
    const tag = event.currentTarget.dataset.tag
    const field = this.inputTarget
    const current = field.value.trim()

    if (current.split(/[,;]/).map((t) => t.trim()).includes(tag)) return

    field.value = current ? `${current}, ${tag}` : tag
    field.focus()
  }
}
