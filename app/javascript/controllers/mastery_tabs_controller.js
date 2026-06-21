import { Controller } from "@hotwired/stimulus"

// Domain controller for mastery navigation (show + edit screens).
// Manages: group pill switching, sub-tab active state, per-group last-selection
// memory, and Turbo Frame navigation. State is in-memory only — cleared on reload.
export default class extends Controller {
  static targets = ["typeTab", "panel", "masteryTab"]

  lastSelectionByGroup = new Map()

  connect() {
    // Seed per-group memory from server-rendered active state
    this.panelTargets.forEach((panel) => {
      const active = panel.querySelector("[data-mastery-tabs-target='masteryTab'].on")
      if (active) {
        this.lastSelectionByGroup.set(panel.dataset.masteryType, active.href)
      }
    })
  }

  selectType(event) {
    const selected = event.currentTarget
    const index = this.typeTabTargets.indexOf(selected)
    const groupType = selected.dataset.masteryType

    this.typeTabTargets.forEach((tab) => tab.classList.toggle("on", tab === selected))

    this.panelTargets.forEach((panel, i) => panel.classList.toggle("hidden", i !== index))

    const panel = this.panelTargets[index]
    if (!panel) return

    const links = Array.from(panel.querySelectorAll("[data-mastery-tabs-target='masteryTab']"))
    if (!links.length) return

    const lastHref = this.lastSelectionByGroup.get(groupType)
    const target =
      (lastHref && links.find((l) => l.href === lastHref)) || links[0]

    links.forEach((l) => l.classList.toggle("on", l === target))

    const frame = document.getElementById("skill-window")
    if (frame) frame.src = target.href
  }

  selectMastery(event) {
    const selected = event.currentTarget
    const panel = selected.closest("[data-mastery-tabs-target='panel']")
    if (!panel) return

    panel
      .querySelectorAll("[data-mastery-tabs-target='masteryTab']")
      .forEach((l) => l.classList.toggle("on", l === selected))

    this.lastSelectionByGroup.set(panel.dataset.masteryType, selected.href)
    // Turbo Frame navigation handled automatically by data-turbo-frame on the link
  }
}
