import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    dismissAfter: Number
  }

  connect() {
    if (this.hasDismissAfterValue) {
      setTimeout(() => {
        this.dismiss()
      }, this.dismissAfterValue)
    }
  }

  dismiss() {
    this.element.remove()
  }
} 