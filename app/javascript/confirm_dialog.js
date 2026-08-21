export default function confirmDialog(message) {
  const dialog = document.getElementById("turbo-confirm")
  const cancelButton = dialog.querySelector("[data-turbo-confirm-cancel]")
  const confirmButton = dialog.querySelector("[data-turbo-confirm-confirm]")

  dialog.querySelector("[data-turbo-confirm-message]").textContent = message
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    const settle = (result) => {
      cancelButton.removeEventListener("click", onCancel)
      confirmButton.removeEventListener("click", onConfirm)
      dialog.removeEventListener("close", onClose)
      resolve(result)
    }

    const onCancel = () => { dialog.close("cancel") }
    const onConfirm = () => { dialog.close("confirm") }
    const onClose = () => { settle(dialog.returnValue === "confirm") }

    cancelButton.addEventListener("click", onCancel)
    confirmButton.addEventListener("click", onConfirm)
    dialog.addEventListener("close", onClose)
  })
}
