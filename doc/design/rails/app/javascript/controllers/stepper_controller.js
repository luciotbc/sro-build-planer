import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stepper"
// Drives a skill row's − / + buttons. Optimistically updates the level label,
// clamps to [0, max], disables buttons at the bounds, then PATCHes the server.
// The server may reply with a Turbo Stream that replaces #skill_<id> and the
// summary totals — see hotwire/turbo_stream_stats.turbo_stream.erb.
//
//   targets : level, inc, dec
//   values  : level:Number, max:Number, url:String
//
//   <div data-controller="stepper"
//        data-stepper-level-value="9" data-stepper-max-value="42"
//        data-stepper-url-value="/skills/42">
export default class extends Controller {
  static targets = ["level", "inc", "dec"]
  static values  = { level: Number, max: Number, url: String }

  inc()  { /* this.set(this.levelValue + 1) */ }
  dec()  { /* this.set(this.levelValue - 1) */ }
  info() { /* open the skill info sheet */ }

  set(next) {
    // clamp 0..max, write levelTarget.textContent, toggle disabled at bounds,
    // then: patch(this.urlValue, { level: next }) with the Turbo Stream accept header.
  }

  levelValueChanged() { /* sync UI when value changes from outside (Turbo) */ }
}
