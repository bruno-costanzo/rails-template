import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "pending"]

  connect() {
    this.observer = new MutationObserver(() => this.settle())
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true, characterData: true })
    this.scrollToEnd()
  }

  disconnect() {
    this.observer.disconnect()
  }

  awaiting() {
    this.pendingTarget.classList.remove("hidden")
    this.scrollToEnd()
  }

  settle() {
    if (this.answered()) this.pendingTarget.classList.add("hidden")
    this.scrollToEnd()
  }

  answered() {
    const bubbles = this.messagesTarget.querySelectorAll(".chat-start .chat-bubble")
    const last = bubbles[bubbles.length - 1]
    return Boolean(last && last.textContent.trim().length > 0)
  }

  scrollToEnd() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
