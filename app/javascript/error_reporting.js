const ENDPOINT = "/javascript_errors"
const MAX_REPORTS_PER_PAGE = 5
const MAX_MESSAGE_LENGTH = 1000
const MAX_STACK_LENGTH = 4000

let reported = 0

function csrfToken() {
  const meta = document.querySelector("meta[name=csrf-token]")
  return meta && meta.content
}

function report(message, stack) {
  if (!message || reported >= MAX_REPORTS_PER_PAGE) return

  reported++

  const headers = { "Content-Type": "application/json" }
  const token = csrfToken()
  if (token) headers["X-CSRF-Token"] = token

  fetch(ENDPOINT, {
    method: "POST",
    headers: headers,
    body: JSON.stringify({
      message: String(message).slice(0, MAX_MESSAGE_LENGTH),
      stack: String(stack || "").slice(0, MAX_STACK_LENGTH),
      url: window.location.href
    }),
    keepalive: true
  }).catch(() => {})
}

export default function reportJavascriptErrors() {
  window.addEventListener("error", (event) => {
    report(event.message, event.error && event.error.stack)
  })

  window.addEventListener("unhandledrejection", (event) => {
    const reason = event.reason
    report(reason && reason.message ? reason.message : String(reason), reason && reason.stack)
  })
}
