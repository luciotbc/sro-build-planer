import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
// Thin wrapper over the native <dialog> element. Powers shared/modal,
// shared/drawer and shared/sheet — Esc and focus-trap are native; this
// opens/closes and handles backdrop clicks.
//
//   values  : open:Boolean — showModal() on connect (default true)
export default class extends Controller {
  static values = { open: { type: Boolean, default: true } }

  connect() {
    if (this.openValue && !this.element.open) this.element.showModal()
  }

  open() {
    if (!this.element.open) this.element.showModal()
  }

  close() {
    this.element.close()
    // Dialogs rendered inside a turbo frame are removed so they can be
    // re-requested; static dialogs (e.g. login) just close.
    const frame = this.element.closest("turbo-frame")
    if (frame) this.element.remove()
  }

  backdropClose(event) {
    if (event.target === this.element) this.close()
  }

  stop(event) {
    event.stopPropagation()
  }
}
