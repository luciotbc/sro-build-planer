import { Controller } from "@hotwired/stimulus"

// A clamped numeric stepper. Increment/decrement keep levelValue within
// [minValue, maxValue] and render the current value into the output target.
export default class extends Controller {
  static values = {
    level: Number,
    min: { type: Number, default: 0 },
    max: Number,
  }
  static targets = ["output"]

  connect() {
    this.render()
  }

  increment() {
    this.levelValue = Math.min(this.maxValue, this.levelValue + 1)
    this.render()
  }

  decrement() {
    this.levelValue = Math.max(this.minValue, this.levelValue - 1)
    this.render()
  }

  render() {
    this.outputTarget.textContent = this.levelValue
  }
}
