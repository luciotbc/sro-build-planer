import { Controller } from "@hotwired/stimulus"

// Enables the destructive submit button only while the typed confirmation
// matches the expected word exactly. UX guard only — the server re-checks
// the confirmation (Users::DeleteAccountService).
export default class extends Controller {
  static targets = ["input", "submit"]
  static values = { word: String }

  check() {
    this.submitTarget.disabled = this.inputTarget.value !== this.wordValue
  }
}
