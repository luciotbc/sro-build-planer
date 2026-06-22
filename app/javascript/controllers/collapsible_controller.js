import { Controller } from "@hotwired/stimulus"

// Toggles a body section open/closed. Works with any container.
// Targets: body (the section to show/hide), chevron (icon that rotates)
export default class extends Controller {
  static targets = ["body", "chevron"]
  static values = { open: { type: Boolean, default: true } }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    if (this.hasBodyTarget) {
      this.bodyTarget.hidden = !this.openValue
    }
    if (this.hasChevronTarget) {
      this.chevronTarget.textContent = this.openValue ? "▾" : "▸"
    }
  }
}
