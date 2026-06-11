import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
// Toggles an active class across [data-tabs-target="tab"] buttons and emits a
// `tabs:change` event ({ id, name }) other controllers / Turbo Frames can hear.
//
//   targets : tab        — each clickable tab button (carries data-tab-id)
//   classes : active     — class applied to the selected tab (data-tabs-active-class)
//   values  : name:String— logical group name broadcast on change
//
//   <div data-controller="tabs" data-tabs-active-class="on" data-tabs-name-value="group">
//     <button data-tabs-target="tab" data-tab-id="weapon" data-action="tabs#select">Weapon</button>
//   </div>
export default class extends Controller {
  static targets = ["tab"]
  static classes = ["active"]
  static values  = { name: String }

  select(event) {
    // 1. move the active class to event.currentTarget
    // 2. dispatch("change", { detail: { id, name: this.nameValue } })
    //    → e.g. swap a Turbo Frame's src, or filter a list
  }
}
