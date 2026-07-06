import { Controller } from "@hotwired/stimulus"

// Owns the sign-in, sign-up and "check your email" dialogs so a single
// controller can switch between them (sign-in ⇄ sign-up, and "Got it" → sign-in)
// and auto-open the confirmation dialog after a successful registration.
export default class extends Controller {
  static targets = ["login", "signup", "confirm"]

  connect() {
    if (this.hasConfirmTarget) {
      this.confirmTarget.showModal()
    }
  }

  showLogin() {
    this.#open(this.loginTarget)
  }

  showSignup() {
    this.#open(this.signupTarget)
  }

  close() {
    this.#dialogs().forEach((dialog) => dialog.close())
  }

  // Used only by the "check your email" dialog; the sign-in and sign-up
  // dialogs deliberately omit this action so backdrop clicks never dismiss them.
  backdropClose(event) {
    if (event.target === event.currentTarget) {
      event.currentTarget.close()
    }
  }

  #open(dialog) {
    this.#dialogs().forEach((other) => {
      if (other !== dialog) other.close()
    })
    dialog.showModal()
  }

  #dialogs() {
    return [
      this.hasLoginTarget && this.loginTarget,
      this.hasSignupTarget && this.signupTarget,
      this.hasConfirmTarget && this.confirmTarget,
    ].filter(Boolean)
  }
}
