import { Controller } from "@hotwired/stimulus"

// Single-select tab group. Marks the clicked tab active, clears the others,
// and dispatches a "tabs:change" event carrying the selected tab's label.
export default class extends Controller {
  static targets = ["tab"]

  select(event) {
    const selected = event.currentTarget

    this.tabTargets.forEach((tab) => {
      tab.classList.toggle("on", tab === selected)
    })

    this.dispatch("change", {
      detail: { value: selected.textContent.trim() },
    })
  }
}
