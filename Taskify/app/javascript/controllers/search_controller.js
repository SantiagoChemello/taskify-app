import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["form", "input"]
  static values = {
    delay: { type: Number, default: 300 },
    minLength: { type: Number, default: 0 }
  }

  initialize() {
    this.timeout = null
  }

  input(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.search()
    }, this.delayValue)
  }

  keyup(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      clearTimeout(this.timeout)
      this.search()
    }
  }

  change() {
    this.search()
  }

  search() {
    const query = this.inputTarget.value.trim()
    if (query.length >= this.minLengthValue || query.length === 0) {
      this.formTarget.requestSubmit()
    }
  }
} 