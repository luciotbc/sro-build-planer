import { Controller } from "@hotwired/stimulus"

// Wraps the skill editor. Provides snapshot/restore for single-step undo
// of bulk actions (spec 06 R7/R8).
//
// Individual ± stepper clicks persist immediately and are NOT part of the
// undo snapshot. Snapshot is taken before bulk actions (task 012) and
// restored by an undo trigger.
//
// Snapshot format: JSON object mapping "skill-row-<sg_id>" → levelValue.
export default class extends Controller {
  static values = { snapshot: String }

  // Call before any bulk action (R4/R5/R6). Captures current level of
  // every stepper inside this editor into snapshotValue.
  snapshot() {
    const levels = {}
    this.#steppers().forEach((ctrl) => {
      if (ctrl.element.id) levels[ctrl.element.id] = ctrl.levelValue
    })
    this.snapshotValue = JSON.stringify(levels)
  }

  // Restore all stepper levels to the last snapshot, persisting each
  // changed level via the same PATCH endpoint. Called by undo button (012).
  async restore() {
    if (!this.snapshotValue) return
    const levels = JSON.parse(this.snapshotValue)
    const csrfToken =
      document.querySelector('meta[name="csrf-token"]')?.content ?? ""

    await Promise.all(
      this.#steppers()
        .filter((ctrl) => {
          const id = ctrl.element.id
          return id && levels[id] !== undefined && levels[id] !== ctrl.levelValue
        })
        .map(async (ctrl) => {
          const prior = levels[ctrl.element.id]
          ctrl.levelValue = prior
          ctrl.render()
          if (!ctrl.hasUrlValue) return
          const response = await fetch(ctrl.urlValue, {
            method: "PATCH",
            headers: {
              Accept: "text/vnd.turbo-stream.html",
              "Content-Type": "application/x-www-form-urlencoded",
              "X-CSRF-Token": csrfToken,
            },
            body: new URLSearchParams({ side: ctrl.sideValue, level: prior }),
          })
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        })
    )
    this.snapshotValue = ""
  }

  #steppers() {
    return this.application.controllers.filter(
      (c) =>
        c.identifier === "stepper" && this.element.contains(c.element),
    )
  }
}
