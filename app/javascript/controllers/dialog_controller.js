import { Controller } from "@hotwired/stimulus"

// Controls a native <dialog> element: open as modal, close, and
// dismiss when the backdrop (the dialog element itself) is clicked.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close()
    }
  }
}
