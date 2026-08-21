import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "frame"]
  static values = { url: String }

  open() {
    if (!this.frameTarget.src) {
      this.frameTarget.src = this.contextualizedUrl()
    }
    this.dialogTarget.showModal()
  }

  contextualizedUrl() {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("context[page_url]", window.location.href)
    url.searchParams.set("context[user_agent]", navigator.userAgent)
    url.searchParams.set("context[viewport]", `${window.innerWidth}x${window.innerHeight}`)
    return url.toString()
  }
}
