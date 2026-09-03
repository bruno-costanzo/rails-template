import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "docs-theme"

export default class extends Controller {
  static targets = ["option"]

  connect() {
    const stored = window.localStorage.getItem(STORAGE_KEY)
    this.optionTargets.forEach(option => { option.checked = option.value === stored })
  }

  remember(event) {
    window.localStorage.setItem(STORAGE_KEY, event.target.value)
  }
}
