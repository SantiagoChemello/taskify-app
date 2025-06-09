import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  connect() {
    console.log("Password toggle controller connected")
  }

  toggle(event) {
    event.preventDefault()
    console.log("Toggle clicked")
    
    // Toggle password visibility
    const type = this.inputTarget.type === "password" ? "text" : "password"
    this.inputTarget.type = type

    // Toggle icon
    if (type === "password") {
      this.iconTarget.classList.remove("icon-eye-off")
      this.iconTarget.classList.add("icon-eye")
    } else {
      this.iconTarget.classList.remove("icon-eye")
      this.iconTarget.classList.add("icon-eye-off")
    }
  }
} 