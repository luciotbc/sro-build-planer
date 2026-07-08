import { Controller } from "@hotwired/stimulus"

// Anchored dropdown menu (e.g. the topbar user-settings menu). Toggles a
// panel next to its trigger and closes on Esc, outside click, or item
// selection. Keeps the trigger's aria-expanded in sync for a11y.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this.close = this.close.bind(this)
    this.closeOnOutside = this.closeOnOutside.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    this.#stopListening()
  }

  toggle() {
    this.panelTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.closeOnOutside)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  close() {
    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.#stopListening()
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
      this.triggerTarget.focus()
    }
  }

  #stopListening() {
    document.removeEventListener("click", this.closeOnOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }
}
