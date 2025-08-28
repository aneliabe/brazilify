import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="message"
export default class extends Controller {
  static values = { userId: Number }

  connect() {
    const currentUserId = parseInt(document.body.dataset.currentUserId || "0", 10)

    if (this.userIdValue === currentUserId) {
      this.element.classList.add("sent")
      this.element.classList.remove("received")
    } else {
      this.element.classList.add("received")
      this.element.classList.remove("sent")
    }

    // Scroll the new/last message into view smoothly
    this.element.scrollIntoView({ behavior: "smooth", block: "end" })
  }
}
