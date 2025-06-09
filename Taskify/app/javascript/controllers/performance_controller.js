import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="performance"
export default class extends Controller {
  connect() {
    this.measurePageLoad()
    this.observeInteractions()
  }

  measurePageLoad() {
    // Measure page load performance
    if (window.performance && window.performance.timing) {
      const timing = window.performance.timing
      const loadTime = timing.loadEventEnd - timing.navigationStart
      
      // Log performance metrics in development
      if (process.env.NODE_ENV === 'development') {
        console.log('Page Load Performance:', {
          loadTime: `${loadTime}ms`,
          domReady: `${timing.domContentLoadedEventEnd - timing.navigationStart}ms`,
          firstPaint: this.getFirstPaint(),
          largestContentfulPaint: this.getLCP()
        })
      }
    }
  }

  observeInteractions() {
    // Observe long tasks that might cause lag
    if ('PerformanceObserver' in window) {
      try {
        // Observe long tasks
        const longTaskObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (entry.duration > 50) { // Tasks longer than 50ms
              console.warn('Long task detected:', {
                duration: `${entry.duration.toFixed(2)}ms`,
                startTime: `${entry.startTime.toFixed(2)}ms`
              })
            }
          }
        })
        longTaskObserver.observe({ entryTypes: ['longtask'] })

        // Observe layout shifts
        const clsObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (entry.value > 0.1) { // CLS threshold
              console.warn('Layout shift detected:', {
                value: entry.value.toFixed(4),
                sources: entry.sources?.map(s => s.node)
              })
            }
          }
        })
        clsObserver.observe({ entryTypes: ['layout-shift'] })

      } catch (error) {
        // Silently fail if performance observers aren't supported
      }
    }
  }

  getFirstPaint() {
    if ('PerformanceObserver' in window) {
      const paintEntries = performance.getEntriesByType('paint')
      const firstPaint = paintEntries.find(entry => entry.name === 'first-paint')
      return firstPaint ? `${firstPaint.startTime.toFixed(2)}ms` : 'N/A'
    }
    return 'N/A'
  }

  getLCP() {
    if ('PerformanceObserver' in window) {
      const lcpEntries = performance.getEntriesByType('largest-contentful-paint')
      const lcp = lcpEntries[lcpEntries.length - 1]
      return lcp ? `${lcp.startTime.toFixed(2)}ms` : 'N/A'
    }
    return 'N/A'
  }

  // Method to manually track user interactions
  trackInteraction(event) {
    const startTime = performance.now()
    
    // Use requestIdleCallback to measure after the interaction
    if ('requestIdleCallback' in window) {
      requestIdleCallback(() => {
        const endTime = performance.now()
        const duration = endTime - startTime
        
        if (duration > 100) { // Interactions longer than 100ms
          console.warn('Slow interaction detected:', {
            type: event.type,
            target: event.target.tagName,
            duration: `${duration.toFixed(2)}ms`
          })
        }
      })
    }
  }

  disconnect() {
    // Clean up observers if needed
  }
} 