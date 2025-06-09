import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["number"]
  static values = {
    onEnter: Boolean
  }

  connect() {
    if (!this.onEnterValue) {
      this.animateNumbers()
    }
  }

  animateNumbers() {
    this.numberTargets.forEach(element => {
      const endValue = parseFloat(element.dataset.value)
      const duration = 1000
      const startTime = performance.now()
      const startValue = 0

      const updateNumber = (currentTime) => {
        const elapsed = currentTime - startTime
        const progress = Math.min(elapsed / duration, 1)
        
        // Easing function (easeOutQuart)
        const easing = 1 - Math.pow(1 - progress, 4)
        
        const currentValue = startValue + (endValue - startValue) * easing
        element.textContent = Number.isInteger(endValue) ? 
          Math.round(currentValue).toString() : 
          currentValue.toFixed(1)

        if (progress < 1) {
          requestAnimationFrame(updateNumber)
        }
      }

      requestAnimationFrame(updateNumber)
    })
  }

  // Intersection Observer callback
  appear(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.animateNumbers()
      }
    })
  }
} 