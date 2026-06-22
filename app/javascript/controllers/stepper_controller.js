import { Controller } from "@hotwired/stimulus"

// A clamped numeric stepper. When url and side values are set, each ±
// persists immediately via a Turbo Stream PATCH (per-step persistence,
// spec 06 R8). The range slider, however, renders live during the drag
// but persists only once on release (the `change` event) — a single PATCH
// with the final level instead of one per intermediate value. Without url,
// it operates as a pure DOM stepper (used by the design system docs).
//
// Single-step undo for bulk actions (spec 06 R7) is handled by the
// skill-editor controller (task 018), which snapshots all stepper levelValues
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

  #controller = null

  connect() {
    this.render()
  }

  increment() {
    const next = this.#clamp(this.levelValue + 1)
    if (next === this.levelValue) return
    this.levelValue = next
    this.render()
    if (this.hasUrlValue) this.#persist(next)
  }

  decrement() {
    const next = this.#clamp(this.levelValue - 1)
    if (next === this.levelValue) return
    this.levelValue = next
    this.render()
    if (this.hasUrlValue) this.#persist(next)
  }

  // Live visual sync while dragging the slider — no persistence (spec 06 R4
  // slider). The PATCH fires once on release via rangeCommit.
  rangeInput(event) {
    const next = this.#clamp(parseInt(event.target.value, 10))
    if (next === this.levelValue) return
    this.levelValue = next
    this.render()
  }

  // Persists the final slider value on release (the `change` event: mouse-up,
  // blur, or keyboard arrow). One PATCH per drag, not per intermediate tick.
  rangeCommit() {
    if (this.hasUrlValue) this.#persist(this.levelValue)
  }

  render() {
    if (this.hasOutputTarget) this.outputTarget.textContent = this.levelValue
    if (this.hasRangeTarget) {
      this.rangeTarget.value = this.levelValue
      // Drive the brass fill of the styled range track (mastery level bar).
      const span = this.maxValue - this.minValue
      const pct = span > 0 ? ((this.levelValue - this.minValue) / span) * 100 : 0
      this.rangeTarget.style.setProperty("--fill", `${pct}%`)
    }
  }

  #clamp(level) {
    return Math.min(this.maxValue, Math.max(this.minValue, level))
  }

  async #persist(level) {
    // Cancel any still-in-flight PATCH so a superseded response can't clobber
    // the UI out of order. Safe because the level is absolute, not a delta.
    this.#controller?.abort()
    this.#controller = new AbortController()

    this.element.setAttribute("aria-busy", "true")
    const csrfToken =
      document.querySelector('meta[name="csrf-token"]')?.content ?? ""
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": csrfToken,
        },
        body: new URLSearchParams({ side: this.sideValue, level }),
        signal: this.#controller.signal,
      })
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    } catch (error) {
      if (error.name !== "AbortError") throw error
    } finally {
      this.element.removeAttribute("aria-busy")
    }
  }
}
