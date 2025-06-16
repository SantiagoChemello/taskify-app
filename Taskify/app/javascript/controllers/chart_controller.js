import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

// Connects to data-controller="chart"
export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object
  }

  connect() {
    // Use requestAnimationFrame for better performance
    requestAnimationFrame(() => {
      this.initializeChart()
    })
  }

  initializeChart() {
    const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark'
    
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      // Reduce animation duration for better performance
      animation: {
        duration: 400,
        easing: 'easeOutQuart'
      },
      // Disable animations on resize for better performance
      resizeDelay: 0,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          backgroundColor: isDarkMode ? 'rgba(0, 0, 0, 0.8)' : 'rgba(255, 255, 255, 0.9)',
          titleColor: isDarkMode ? '#fff' : '#000',
          bodyColor: isDarkMode ? '#fff' : '#000',
          borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
          borderWidth: 1,
          padding: 10,
          cornerRadius: 8,
          displayColors: false,
          // Optimize tooltip performance
          intersect: false,
          mode: 'index'
        }
      },
      scales: {
        x: {
          grid: {
            color: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
            drawBorder: false
          },
          ticks: {
            color: isDarkMode ? '#9ca3af' : '#64748b',
            maxTicksLimit: 8 // Limit ticks for better performance
          }
        },
        y: {
          grid: {
            color: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
            drawBorder: false
          },
          ticks: {
            color: isDarkMode ? '#9ca3af' : '#64748b',
            maxTicksLimit: 6 // Limit ticks for better performance
          }
        }
      },
      // Optimize performance settings
      elements: {
        point: {
          radius: 3,
          hoverRadius: 5
        }
      },
      interaction: {
        intersect: false,
        mode: 'index'
      }
    }

    // Modify dataset colors based on dark mode
    const data = { ...this.dataValue }
    data.datasets = data.datasets.map(dataset => ({
      ...dataset,
      backgroundColor: isDarkMode ? 
        (dataset.backgroundColor || 'rgba(59, 130, 246, 0.8)') : 
        dataset.backgroundColor,
      borderColor: isDarkMode ? 
        (dataset.borderColor || '#3b82f6') : 
        dataset.borderColor
    }))

    const options = { ...defaultOptions, ...this.optionsValue }
    
    this.chart = new Chart(this.element, {
      type: this.typeValue,
      data: data,
      options: options
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}