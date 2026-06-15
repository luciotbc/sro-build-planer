import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
// Toggles the active class across [data-tabs-target="tab"] buttons and emits
// a `tabs:change` event ({ id, name }) other controllers / frames can hear.
//
//   targets : tab        — each clickable tab button (carries data-tab-id)
//   classes : active     — class applied to the selected tab
//   values  : name:String — logical group name broadcast on change
export default class extends Controller {
  static targets = ["tab"]
  static classes = ["active"]
  static values = { name: String }

  select(event) {
    const tab = event.currentTarget
    this.tabTargets.forEach((t) => {
      t.classList.toggle(this.activeClass, t === tab)
      t.setAttribute("aria-selected", t === tab)
      t.setAttribute("tabindex", t === tab ? "0" : "-1")
    })
    this.dispatch("change", {
      detail: { id: tab.dataset.tabId, name: this.nameValue }
    })
  }

  navigate(event) {
    const { key } = event
    if (!["ArrowLeft", "ArrowRight"].includes(key)) return
    event.preventDefault()
    const tabs = this.tabTargets
    const currentIndex = tabs.findIndex((t) => t.getAttribute("aria-selected") === "true")
    const nextIndex =
      key === "ArrowRight"
        ? (currentIndex + 1) % tabs.length
        : (currentIndex - 1 + tabs.length) % tabs.length
    tabs[nextIndex].focus()
    tabs[nextIndex].click()
  }
}
