import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  #timer = null

  connect() {
    if (this.durationValue > 0) {
      this.#timer = setTimeout(() => this.dismiss(), this.durationValue)
    }
  }

  disconnect() {
    clearTimeout(this.#timer)
  }

  dismiss() {
    clearTimeout(this.#timer)
    this.element.remove()
  }
}
