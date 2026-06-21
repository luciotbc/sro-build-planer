import { Controller } from "@hotwired/stimulus"

// Single-select tab group. Marks the clicked tab active, clears the others.
// Section level: controls mastery type pills + shows/hides panels, ensures active sub-tab.
// Panel level: controls mastery sub-tabs, marks one active.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const selected = event.currentTarget
    const index = this.tabTargets.indexOf(selected)
    const isButton = selected.tagName === "BUTTON"

    // Mark selected tab active
    this.tabTargets.forEach((tab) => {
      tab.classList.toggle("on", tab === selected)
    })

    // Show/hide panels + ensure visible panel has an active sub-tab
    // Only if we're at section level (button click), not panel level (link click)
    if (isButton && this.hasPanelTarget) {
      this.panelTargets.forEach((panel, i) => {
        const isVisible = i === index
        panel.classList.toggle("hidden", !isVisible)

        // If panel is now visible, ensure it has an active sub-tab and trigger its click
        if (isVisible) {
          let activeSubTab = panel.querySelector("[data-tabs-target='tab'].on")
          if (!activeSubTab) {
            activeSubTab = panel.querySelector("[data-tabs-target='tab']")
            if (activeSubTab) {
              activeSubTab.classList.add("on")
            }
          }
          // Trigger click on active sub-tab to update skill-window frame
          if (activeSubTab) {
            activeSubTab.click()
          }
        }
      })
    }

    this.dispatch("change", {
      detail: { value: selected.textContent.trim() },
    })
  }
}
