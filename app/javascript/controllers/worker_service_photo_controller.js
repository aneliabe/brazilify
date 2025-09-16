import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]

  connect() {

    this._onHide = () => {
      const active = document.activeElement
      if (active && this.element.contains(active)) active.blur()
    }

    this._onShown = () => {
      this.element.querySelector(".photo-nav-btn")?.focus()
    }

    this.element.addEventListener("hide.bs.modal", this._onHide)
    this.element.addEventListener("shown.bs.modal", this._onShown)
  }

  disconnect() {
    this.element.removeEventListener("hide.bs.modal", this._onHide)
    this.element.removeEventListener("shown.bs.modal", this._onShown)
  }

  // zoom
  toggleZoom(event) {
    const image = this.imageTarget
    if (!image) return

    if (image.classList.contains("zoomed")) {
      // Zoom out
      image.classList.remove("zoomed")
      image.style.transformOrigin = "center"
    } else {
      // Zoom in at click position
      const rect = image.getBoundingClientRect()
      const x = ((event.clientX - rect.left) / rect.width) * 100
      const y = ((event.clientY - rect.top) / rect.height) * 100

      image.style.transformOrigin = `${x}% ${y}%`
      image.classList.add("zoomed")
    }
  }
}
