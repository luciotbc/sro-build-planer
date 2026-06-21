import { Controller } from "@hotwired/stimulus"

// Single-select tab group. Marks the clicked tab active, clears the others,
// and dispatches a "tabs:change" event carrying the selected tab's label.
// Optional: add data-tabs-target="panel" siblings — one per tab, shown by index.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const selected = event.currentTarget
    const index = this.tabTargets.indexOf(selected)

    this.tabTargets.forEach((tab) => {
      tab.classList.toggle("on", tab === selected)
    })

    if (this.hasPanelTarget) {
      this.panelTargets.forEach((panel, i) => {
        panel.classList.toggle("hidden", i !== index)
      })
    }

    this.dispatch("change", {
      detail: { value: selected.textContent.trim() },
    })
  }
}
