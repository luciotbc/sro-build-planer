import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
// Thin wrapper over the native <dialog> element. Powers shared/modal,
// shared/drawer and shared/sheet — backdrop click, Esc and focus-trap are
// native; this just opens/closes and stops backdrop bubbling.
//
//   connect()        — showModal() if you want it open on render
//   open()           — el.showModal()
//   close()          — el.close()  (CSS exit animation can run before remove)
//   backdropClose(e) — close when the click target IS the <dialog> (the backdrop)
//   stop(e)          — e.stopPropagation() on the inner panel
//
// Turbo tip: render the dialog inside <turbo-frame id="modal"> and call
// open() on turbo:frame-load so a server response pops the editor automatically.
export default class extends Controller {
  open()  { /* this.element.showModal() */ }
  close() { /* this.element.close() */ }
  backdropClose(event) { /* if (event.target === this.element) this.close() */ }
  stop(event) { /* event.stopPropagation() */ }
}
