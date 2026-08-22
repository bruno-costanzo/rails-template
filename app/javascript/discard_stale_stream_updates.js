export default function discardStaleStreamUpdates() {
  const knownVersions = new Map()

  document.addEventListener("turbo:before-stream-render", (event) => {
    const newStream = event.detail.newStream
    if (newStream.action !== "append") return

    const incoming = newStream.templateElement.content.firstElementChild
    if (!incoming?.id || !incoming.dataset.version) return

    const incomingVersion = Number(incoming.dataset.version)
    const knownVersion = knownVersions.get(incoming.id)

    if (knownVersion !== undefined && incomingVersion < knownVersion) {
      event.preventDefault()
      return
    }

    knownVersions.set(incoming.id, incomingVersion)
  })
}
