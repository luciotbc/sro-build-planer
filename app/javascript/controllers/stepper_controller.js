import { Controller } from "@hotwired/stimulus"

// A clamped numeric stepper. When url and side values are set, each ±
// persists immediately via a Turbo Stream PATCH (per-step persistence,
// spec 06 R8). Without url, it operates as a pure DOM stepper (used by
// the design system docs).
//
// Single-step undo for bulk actions (spec 06 R7) is handled by the
// skill-editor controller (010/03), which snapshots all stepper levelValues
// before each bulk action and re-submits deltas on undo.
export default class extends Controller {
  static values = {
    level: Number,
    min: { type: Number, default: 0 },
    max: Number,
    url: String,
    side: String,
  }
  static targets = ["output", "range"]

  connect() {
    this.render()
  }

  increment() {
    const next = Math.min(this.maxValue, this.levelValue + 1)
    if (next === this.levelValue) return
    this.levelValue = next
    this.render()
    if (this.hasUrlValue) this.#persist(next)
  }

  decrement() {
    const next = Math.max(this.minValue, this.levelValue - 1)
    if (next === this.levelValue) return
    this.levelValue = next
    this.render()
    if (this.hasUrlValue) this.#persist(next)
  }

  // Syncs stepper from a range <input> change (spec 06 R4 slider).
  rangeInput(event) {
    const next = Math.min(
      this.maxValue,
      Math.max(this.minValue, parseInt(event.target.value, 10))
    )
    if (next === this.levelValue) return
    this.levelValue = next
    this.render()
    if (this.hasUrlValue) this.#persist(next)
  }

  // Sets level to max and persists — used by "Max mastery" button (spec 06 R4).
  setMax() {
    if (this.levelValue === this.maxValue) return
    this.levelValue = this.maxValue
    this.render()
    if (this.hasUrlValue) this.#persist(this.maxValue)
  }

  render() {
    if (this.hasOutputTarget) this.outputTarget.textContent = this.levelValue
    if (this.hasRangeTarget) this.rangeTarget.value = this.levelValue
  }

  async #persist(level) {
    const csrfToken =
      document.querySelector('meta[name="csrf-token"]')?.content ?? ""
    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: new URLSearchParams({ side: this.sideValue, level }),
    })
    const html = await response.text()
    Turbo.renderStreamMessage(html)
  }
}
