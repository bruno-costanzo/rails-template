export default function discardStaleStreamUpdates() {
  const knownVersions = new Map()
  const tombstonedIds = new Set()

  document.addEventListener("turbo:before-stream-render", (event) => {
    const newStream = event.detail.newStream

    if (newStream.action === "remove") {
      if (newStream.target) tombstonedIds.add(newStream.target)
      return
    }

    if (newStream.action !== "append") return

    if (targetsSettledMessage(newStream.target)) {
      event.preventDefault()
      return
    }

    const children = Array.from(newStream.templateElement.content.children)
    const incoming = children[0]
    if (!incoming?.id || !incoming.dataset.version) return

    const targetElements = newStream.targetElements

    try {
      children.forEach((child) => applyVersionedChild(child, targetElements, knownVersions, tombstonedIds))
      event.preventDefault()
    } catch {
      return
    }
  })
}

function applyVersionedChild(child, targetElements, knownVersions, tombstonedIds) {
  const id = child.id
  const version = id ? child.dataset.version : undefined

  if (id && version) {
    const incomingVersion = Number(version)
    const knownVersion = knownVersions.get(id)
    const isStale = tombstonedIds.has(id) || (knownVersion !== undefined && incomingVersion < knownVersion)
    if (isStale) return

    knownVersions.set(id, incomingVersion)
  }

  const content = child.cloneNode(true)
  const existing = id ? document.getElementById(id) : null

  if (existing) {
    content.dataset.settled = "true"
    existing.replaceWith(content)
  } else {
    targetElements.forEach((target) => target.append(content))
  }
}

function targetsSettledMessage(target) {
  const match = /^(message_\d+)_content$/.exec(target || "")
  if (!match) return false

  return document.getElementById(match[1])?.dataset.settled === "true"
}
