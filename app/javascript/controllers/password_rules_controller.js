import { Controller } from "@hotwired/stimulus"

// Live "Password must have" checklist. Hidden until the user starts editing
// the new-password (or confirmation) field, then each rule item flips between
// unmet/met as the values change. Pure UX sugar — the server-side model
// validations remain authoritative.
//
// Rule items carry data-rule="length|uppercase|number|match". The "match"
// rule is skipped automatically when there is no confirmation target
// (e.g. the registration form has a single password field).
export default class extends Controller {
  static targets = ["password", "confirmation", "panel", "rule"]

  check() {
    this.reveal()
    const password = this.passwordTarget.value
    const confirmation = this.hasConfirmationTarget
      ? this.confirmationTarget.value
      : null

    this.ruleTargets.forEach((item) => {
      const met = this.satisfied(item.dataset.rule, password, confirmation)
      item.dataset.met = met
    })
  }

  reveal() {
    if (this.hasPanelTarget) this.panelTarget.hidden = false
  }

  satisfied(rule, password, confirmation) {
    switch (rule) {
      case "length":
        return password.length >= 8
      case "uppercase":
        return /[A-Z]/.test(password)
      case "number":
        return /\d/.test(password)
      case "match":
        return confirmation !== null && password !== "" && password === confirmation
      default:
        return false
    }
  }
}
