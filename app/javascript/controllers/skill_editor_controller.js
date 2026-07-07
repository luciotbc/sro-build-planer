import { Controller } from "@hotwired/stimulus"

// Single-step undo for bulk editor actions (spec 06 R7/R8). Attached to the
// persistent turbo-frame wrapper so the snapshot survives the Turbo Stream
// refresh that bulk actions trigger (the stream replaces mastery-header and
// each skill row, not the frame itself).
//
// beforeBulk (wired to each bulk form's submit) captures plain data — one
// {url, side, level} entry per stepper — because the stepper DOM nodes are
// replaced by the stream response and element references would go stale.
// restore() re-finds each stepper by its PATCH url and re-submits the
// snapshotted absolute level through the same endpoints the steppers use;
// no dedicated backend. One level of history: taking a new snapshot
// overwrites the previous one, and restore() clears it.
export default class extends Controller {
  static targets = ["undo"]
  static values = { snapshot: Array }

  beforeBulk() {
    this.snapshotValue = this.#steppers().map((el) => ({
      url: el.dataset.stepperUrlValue,
      side: el.dataset.stepperSideValue,
      level: parseInt(el.dataset.stepperLevelValue, 10),
    }))
  }

  async restore() {
    const snapshot = this.snapshotValue
    this.snapshotValue = []
    // Sequential on purpose: each PATCH response is a Turbo Stream that
    // replaces DOM nodes; parallel responses could interleave and clobber.
    for (const entry of snapshot) {
      const el = this.#steppers().find(
        (s) => s.dataset.stepperUrlValue === entry.url
      )
      if (!el) continue
      if (parseInt(el.dataset.stepperLevelValue, 10) === entry.level) continue
      await this.#persist(entry)
    }
  }

  // Mastery tab switches navigate the frame; the snapshot belongs to the
  // previous mastery, so drop it (R7: scoped to the active mastery).
  clearSnapshot() {
    this.snapshotValue = []
  }

  snapshotValueChanged() {
    if (!this.hasUndoTarget) return
    this.undoTarget.disabled = this.snapshotValue.length === 0
  }

  // The undo button is re-rendered disabled on frame navigation; re-sync it
  // with the current snapshot when it (re)appears.
  undoTargetConnected() {
    this.snapshotValueChanged()
  }

  #steppers() {
    return Array.from(
      this.element.querySelectorAll('[data-controller~="stepper"]')
    )
  }

  async #persist({ url, side, level }) {
    const csrfToken =
      document.querySelector('meta[name="csrf-token"]')?.content ?? ""
    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: new URLSearchParams({ side, level }),
    })
    const html = await response.text()
    Turbo.renderStreamMessage(html)
  }
}
