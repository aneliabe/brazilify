import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["services"]

  toggle(event) {
    event.preventDefault()
    const servicesList = event.currentTarget.nextElementSibling
    if (servicesList.style.display === "none") {
      servicesList.style.display = "block"
    } else {
      servicesList.style.display = "none"
    }
  }
}