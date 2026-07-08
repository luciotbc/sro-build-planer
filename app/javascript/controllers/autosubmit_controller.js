import { Controller } from "@hotwired/stimulus"

// Submits the form it is attached to when an input fires the bound action,
// e.g. a settings toggle: <form data-controller="autosubmit"> with
// data-action="change->autosubmit#submit" on the checkbox.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
