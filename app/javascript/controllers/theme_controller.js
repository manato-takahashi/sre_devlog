import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = [ "icon" ]

  connect() {
    this.applyTheme(this.currentTheme)
  }

  toggle() {
    const newTheme = this.currentTheme === "dark" ? "light" : "dark"
    localStorage.setItem("theme", newTheme)
    this.applyTheme(newTheme)
  }

  applyTheme(theme) {
    document.documentElement.style.colorScheme = theme
    if (this.hasIconTarget) {
      this.iconTarget.textContent = theme === "dark" ? "🌞" : "🌙"
    }
  }

  get currentTheme() {
    return localStorage.getItem("theme") || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  }
}
