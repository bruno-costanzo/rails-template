import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "frame"]
  static values = { url: String }

  open() {
    if (!this.frameTarget.src) {
      this.frameTarget.src = this.urlValue
    }
    this.dialogTarget.showModal()
  }
}
