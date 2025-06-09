import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["navItem", "section", "content"]

  connect() {
    this.adjustContentHeight();
    this.forceTextColors();
    this.setupNotificationToggles();

    // Set up theme selector
    const themeSelector = document.getElementById('theme-selector')
    if (themeSelector) {
      const currentTheme = localStorage.getItem('theme') || 'auto'
      themeSelector.value = currentTheme
      
      themeSelector.addEventListener('change', (e) => {
        const theme = e.target.value
        localStorage.setItem('theme', theme)
        this.applyTheme(theme)
        
        // Show user feedback
        const themeNames = { auto: 'Automático', light: 'Claro', dark: 'Oscuro' }
        this.showNotification(`Tema cambiado a: ${themeNames[theme]}`)
      })
    }

    // Set up animations toggle
    const animationsToggle = document.getElementById('animations-toggle')
    if (animationsToggle) {
      const animationsEnabled = localStorage.getItem('animations') !== 'false'
      animationsToggle.checked = animationsEnabled
      
      animationsToggle.addEventListener('change', (e) => {
        const enabled = e.target.checked
        localStorage.setItem('animations', enabled)
        document.body.classList.toggle('no-animations', !enabled)
        
        // Show user feedback
        this.showNotification(`Animaciones ${enabled ? 'habilitadas' : 'deshabilitadas'}`)
      })
    }

    // Set up tasks per page selector
    const tasksPerPageSelector = document.getElementById('tasks-per-page-selector')
    if (tasksPerPageSelector) {
      const currentTasksPerPage = localStorage.getItem('tasksPerPage') || '10'
      tasksPerPageSelector.value = currentTasksPerPage
      
      tasksPerPageSelector.addEventListener('change', (e) => {
        const tasksPerPage = e.target.value
        localStorage.setItem('tasksPerPage', tasksPerPage)
        console.log(`Tasks per page set to: ${tasksPerPage}`)
        
        // Show user feedback
        this.showNotification(`Configuración guardada: ${tasksPerPage} tareas por página`)
      })
    }

    // Set up confirmation toggle
    const confirmationToggle = document.getElementById('confirmation-toggle')
    if (confirmationToggle) {
      const confirmationEnabled = localStorage.getItem('confirmDeletion') !== 'false'
      confirmationToggle.checked = confirmationEnabled
      
      confirmationToggle.addEventListener('change', (e) => {
        const enabled = e.target.checked
        localStorage.setItem('confirmDeletion', enabled)
        console.log(`Confirmation before deletion: ${enabled ? 'enabled' : 'disabled'}`)
        
        // Show user feedback
        this.showNotification(`Confirmación de eliminación ${enabled ? 'habilitada' : 'deshabilitada'}`)
      })
    }
  }
  
  adjustContentHeight() {
    const activeSection = this.sectionTargets.find(s => s.classList.contains('active'));
    if (activeSection) {
      // Remove fixed height to allow natural content flow
      this.contentTarget.style.height = 'auto';
      this.contentTarget.style.minHeight = '600px';
    }
  }

  switchSection(event) {
    const clickedItem = event.currentTarget;
    const sectionName = clickedItem.dataset.section;
    const targetSection = this.sectionTargets.find(s => s.id === `${sectionName}-section`);

    if (!targetSection || targetSection.classList.contains('active')) {
      return; // Do nothing if it's already active
    }

    // Get the current active section to fade it out
    const activeSection = this.sectionTargets.find(s => s.classList.contains('active'));

    // Simplified content switching without complex height animations
    this.contentTarget.style.height = 'auto';
    this.contentTarget.style.minHeight = '600px';

    // Switch active classes on nav
    this.navItemTargets.forEach(item => item.classList.remove('active'));
    clickedItem.classList.add('active');

    // Switch active classes on sections
    if (activeSection) {
      activeSection.classList.remove('active');
    }
    targetSection.classList.add('active');
    
    // Ensure content height is properly adjusted
    setTimeout(() => {
        this.adjustContentHeight();
    }, 100); // Reduced timeout for faster response
  }

  forceTextColors() {
    // Force white text in dark mode for settings navigation
    const observer = new MutationObserver(() => {
      this.updateTextColors();
    });
    
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['class']
    });
    
    // Initial call
    this.updateTextColors();
  }
  
  updateTextColors() {
    const isDarkMode = document.documentElement.classList.contains('dark-mode');
    
    // Handle navigation text
    const settingsNavItems = document.querySelectorAll('.settings-nav-item span:not(.icon)');
    settingsNavItems.forEach(span => {
      if (isDarkMode) {
        span.style.color = '#FFFFFF';
        span.style.setProperty('color', '#FFFFFF', 'important');
      } else {
        span.style.color = '#000000';
        span.style.setProperty('color', '#000000', 'important');
      }
    });
    
    // Handle secondary/description text
    const secondaryTextElements = document.querySelectorAll('.setting-info p, .notification-setting p, .preference-setting p, .settings-content p, .card-content p');
    secondaryTextElements.forEach(element => {
      if (isDarkMode) {
        element.style.color = '#D1D5DB';
        element.style.fontSize = '0.875rem';
        element.style.lineHeight = '1.4';
        element.style.setProperty('color', '#D1D5DB', 'important');
      } else {
        element.style.color = '#6B7280';
        element.style.fontSize = '0.875rem';
        element.style.lineHeight = '1.4';
        element.style.setProperty('color', '#6B7280', 'important');
      }
    });
  }

  applyTheme(theme) {
    const body = document.body
    
    if (theme === 'dark') {
      body.classList.add('dark-mode')
    } else if (theme === 'light') {
      body.classList.remove('dark-mode')
    } else {
      // Auto theme - check system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      body.classList.toggle('dark-mode', prefersDark)
    }
    
    // Force text colors after theme change
    setTimeout(() => this.updateTextColors(), 100);
  }

  showNotification(message) {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = 'settings-notification'
    notification.textContent = message
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: var(--accent-primary);
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      z-index: 1000;
      font-size: 14px;
      font-weight: 500;
      transform: translateX(100%);
      transition: transform 0.3s ease;
    `
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 100)
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    }, 3000)
  }

  setupNotificationToggles() {
    // Set up notification toggles
    const notificationToggles = document.querySelectorAll('.notification-setting input[type="checkbox"]')
    
    notificationToggles.forEach((toggle, index) => {
      const settingNames = ['overdueTasks', 'dailyReminders', 'upcomingTasks']
      const settingName = settingNames[index] || `notification_${index}`
      
      // Load saved state
      const saved = localStorage.getItem(settingName)
      if (saved !== null) {
        toggle.checked = saved === 'true'
      }
      
      // Add event listener
      toggle.addEventListener('change', (e) => {
        const enabled = e.target.checked
        localStorage.setItem(settingName, enabled)
        
        const settingLabels = [
          'Notificaciones de tareas vencidas',
          'Recordatorios diarios',
          'Alertas de tareas próximas a vencer'
        ]
        const label = settingLabels[index] || 'Notificación'
        
        this.showNotification(`${label} ${enabled ? 'habilitadas' : 'deshabilitadas'}`)
      })
    })
  }
} 