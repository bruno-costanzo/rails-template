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
    const primary = []
    const secondary = []

    for (const entry of this.entries) {
      if (this.headingHaystack(entry).includes(query)) {
        primary.push({ entry, snippet: null })
      } else if ((entry.body || "").toLowerCase().includes(query)) {
        secondary.push({ entry, snippet: this.snippet(entry.body, query) })
      }
    }

    this.render([ ...primary, ...secondary ].slice(0, LIMIT))
  }

  render(matches) {
    this.resultsTarget.replaceChildren(...matches.map((match, position) => this.item(match, position)))
    this.emptyTarget.classList.toggle("hidden", matches.length > 0)
    this.select(0)
  }

  item({ entry, snippet }, position) {
    const link = document.createElement("a")
    link.href = entry.path
    link.className = "flex flex-col items-start gap-0.5"
    link.dataset.position = position
    link.append(this.line(entry.heading || entry.title, "truncate w-full"))

    const detail = snippet || (entry.heading ? entry.title : entry.summary)
    if (detail) link.append(this.line(detail, "truncate w-full text-xs text-base-content/60"))

    const item = document.createElement("li")
    item.append(link)
    return item
  }

  snippet(body, query) {
    const haystack = body.toLowerCase()
    const index = haystack.indexOf(query)
    if (index === -1) return body.slice(0, 80)

    const start = Math.max(0, index - 30)
    const end = Math.min(body.length, index + query.length + 30)

    return `${start > 0 ? "…" : ""}${body.slice(start, end).trim()}${end < body.length ? "…" : ""}`
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

  headingHaystack(entry) {
    return `${entry.title} ${entry.heading || ""} ${entry.summary || ""}`.toLowerCase()
  }
}
