import { Controller } from "@hotwired/stimulus"

// Copies the text value to the clipboard and briefly swaps the icon
// target for the check target as visual confirmation.
export default class extends Controller {
  static values = { text: String }
  static targets = ["icon", "check"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
    } catch {
      this.#legacyCopy()
    }
    this.#toggle(true)
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.#toggle(false), 1500)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  // Fallback for contexts where the async Clipboard API is unavailable
  // or permission-denied (older browsers, embedded webviews).
  #legacyCopy() {
    const textarea = document.createElement("textarea")
    textarea.value = this.textValue
    textarea.setAttribute("readonly", "")
    textarea.style.position = "absolute"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    textarea.remove()
  }

  #toggle(copied) {
    this.iconTargets.forEach((el) => el.classList.toggle("hidden", copied))
    this.checkTargets.forEach((el) => el.classList.toggle("hidden", !copied))
  }
}
