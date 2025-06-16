import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  connect() {
    this.initializeTheme()
  }

  initializeTheme() {
    // Check if user has a theme preference in localStorage
    const savedTheme = localStorage.getItem('theme')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
      this.enableDarkMode()
    } else {
      this.enableLightMode()
    }

    this.updateToggleIcon()
  }

  toggle(event) {
    event.preventDefault()
    if (document.documentElement.classList.contains('dark-mode')) {
      this.enableLightMode()
    } else {
      this.enableDarkMode()
    }
    this.updateToggleIcon()
  }

  enableDarkMode() {
    document.documentElement.classList.add('dark-mode')
    localStorage.setItem('theme', 'dark')
  }

  enableLightMode() {
    document.documentElement.classList.remove('dark-mode')
    localStorage.setItem('theme', 'light')
  }

  updateToggleIcon() {
    const toggleButton = document.querySelector('.theme-toggle')
    if (toggleButton) {
      const isDark = document.documentElement.classList.contains('dark-mode')
      
      if (isDark) {
        toggleButton.innerHTML = '<span class="icon icon-sun"></span>'
        toggleButton.title = 'Switch to light mode'
      } else {
        toggleButton.innerHTML = '<span class="icon icon-moon"></span>'
        toggleButton.title = 'Switch to dark mode'
      }
    }
  }
} 