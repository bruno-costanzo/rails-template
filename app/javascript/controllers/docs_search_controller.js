import { Controller } from "@hotwired/stimulus"

const LIMIT = 20

export default class extends Controller {
  static targets = ["dialog", "input", "results", "empty", "index"]

  connect() {
    this.entries = JSON.parse(this.indexTarget.textContent)
    this.shortcut = this.shortcut.bind(this)
    window.addEventListener("keydown", this.shortcut)
  }

  disconnect() {
    window.removeEventListener("keydown", this.shortcut)
  }

  shortcut(event) {
    if (event.key !== "k" || !(event.metaKey || event.ctrlKey)) return

    event.preventDefault()
    this.open()
  }

  open() {
    this.inputTarget.value = ""
    this.filter()
    this.dialogTarget.showModal()
    this.inputTarget.focus()
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const matches = this.entries.filter(entry => this.haystack(entry).includes(query)).slice(0, LIMIT)

    this.render(matches)
  }

  render(matches) {
    this.resultsTarget.replaceChildren(...matches.map((entry, position) => this.item(entry, position)))
    this.emptyTarget.classList.toggle("hidden", matches.length > 0)
    this.select(0)
  }

  item(entry, position) {
    const link = document.createElement("a")
    link.href = entry.path
    link.className = "flex flex-col items-start gap-0.5"
    link.dataset.position = position
    link.append(this.line(entry.heading || entry.title, "truncate w-full"))

    const detail = entry.heading ? entry.title : entry.summary
    if (detail) link.append(this.line(detail, "truncate w-full text-xs text-base-content/60"))

    const item = document.createElement("li")
    item.append(link)
    return item
  }

  line(text, className) {
    const span = document.createElement("span")
    span.className = className
    span.textContent = text
    return span
  }

  walk(event) {
    if (event.key === "ArrowDown") this.move(event, 1)
    if (event.key === "ArrowUp") this.move(event, -1)
    if (event.key === "Enter") this.follow(event)
  }

  move(event, step) {
    event.preventDefault()
    this.select(this.position + step)
  }

  follow(event) {
    const link = this.links[this.position]
    if (!link) return

    event.preventDefault()
    this.dialogTarget.close()
    link.click()
  }

  select(position) {
    const links = this.links
    if (links.length === 0) return

    this.position = (position + links.length) % links.length
    links.forEach((link, index) => link.classList.toggle("menu-active", index === this.position))
    links[this.position].scrollIntoView({ block: "nearest" })
  }

  get links() {
    return Array.from(this.resultsTarget.querySelectorAll("a"))
  }

  haystack(entry) {
    return `${entry.title} ${entry.heading || ""} ${entry.summary || ""}`.toLowerCase()
  }
}
