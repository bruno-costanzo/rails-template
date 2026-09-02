export default function discardStaleStreamUpdates() {
  const knownVersions = new Map()
  const tombstonedIds = new Set()

  document.addEventListener("turbo:before-stream-render", (event) => {
    const newStream = event.detail.newStream
    const action = newStream.action

    if (action === "remove") {
      if (newStream.target) tombstonedIds.add(newStream.target)
      return
    }

    if (action === "append" && targetsSettledMessage(newStream.target)) {
      event.preventDefault()
      return
    }

    if (action !== "append" && action !== "replace") return

    const incoming = newStream.templateElement.content.firstElementChild
    if (!incoming?.id || !incoming.dataset.version) return

    const version = Number(incoming.dataset.version)
    if (isStale(incoming.id, version, knownVersions, tombstonedIds)) {
      event.preventDefault()
      return
    }

    knownVersions.set(incoming.id, version)
    applyMessageElement(incoming, newStream.targetElements)
    event.preventDefault()
  })
}

function applyMessageElement(incoming, targetElements) {
  const content = incoming.cloneNode(true)
  const existing = document.getElementById(incoming.id)

  if (existing) {
    content.dataset.settled = "true"
    existing.replaceWith(content)
    return
  }

  const targets = targetElements.length > 0 ? targetElements : messagesContainer()
  targets.forEach((target) => target.append(content))
}

function messagesContainer() {
  const container = document.querySelector('[id$="_messages"]')
  return container ? [ container ] : []
}

function isStale(id, version, knownVersions, tombstonedIds) {
  const knownVersion = knownVersions.get(id)
  return tombstonedIds.has(id) || (knownVersion !== undefined && version < knownVersion)
}

function targetsSettledMessage(target) {
  const match = /^(message_\d+)_content$/.exec(target || "")
  if (!match) return false

  return document.getElementById(match[1])?.dataset.settled === "true"
}
