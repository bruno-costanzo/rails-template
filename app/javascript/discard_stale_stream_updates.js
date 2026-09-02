export default function discardStaleStreamUpdates() {
  const knownVersions = new Map()
  const tombstonedIds = new Set()
  const awaitingTarget = new Map()
  const observer = new MutationObserver(() => renderAwaitedStreams())

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

    const incoming = versionedElement(newStream)
    if (!incoming) return

    const version = Number(incoming.dataset.version)
    if (isStale(incoming.id, version)) {
      event.preventDefault()
      return
    }

    knownVersions.set(incoming.id, version)
    if (action !== "replace") return

    incoming.dataset.settled = "true"
    if (document.getElementById(incoming.id)) return

    awaitForTarget(incoming.id, newStream)
    event.preventDefault()
  })

  function isStale(id, version) {
    if (tombstonedIds.has(id)) return true

    const knownVersion = knownVersions.get(id)
    return knownVersion !== undefined && version < knownVersion && Boolean(document.getElementById(id))
  }

  function awaitForTarget(id, newStream) {
    awaitingTarget.set(id, newStream.cloneNode(true))
    if (awaitingTarget.size === 1) observer.observe(document.body, { childList: true, subtree: true })
  }

  function renderAwaitedStreams() {
    awaitingTarget.forEach((stream, id) => {
      if (!document.getElementById(id)) return

      awaitingTarget.delete(id)
      document.body.appendChild(stream)
    })

    if (awaitingTarget.size === 0) observer.disconnect()
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
