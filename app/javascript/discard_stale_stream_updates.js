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

    if (action !== "append") return

    if (targetsSettledMessage(newStream.target)) {
      event.preventDefault()
      return
    }

    const incoming = versionedElement(newStream)
    if (!incoming) return

    const version = Number(incoming.dataset.version)
    if (isStale(incoming.id, version)) {
      event.preventDefault()
      return
    }

    if (knownVersions.has(incoming.id) || document.getElementById(incoming.id)) {
      incoming.dataset.settled = "true"
    }

    knownVersions.set(incoming.id, version)
  })

  function isStale(id, version) {
    if (tombstonedIds.has(id)) return true

    const knownVersion = knownVersions.get(id)
    return knownVersion !== undefined && version < knownVersion
  }
}

function versionedElement(newStream) {
  let element

  try {
    element = newStream.templateElement.content.firstElementChild
  } catch {
    return null
  }

  return element?.id && element.dataset.version ? element : null
}

function targetsSettledMessage(target) {
  const match = /^(message_\d+)_content$/.exec(target || "")
  if (!match) return false

  return document.getElementById(match[1])?.dataset.settled === "true"
}
