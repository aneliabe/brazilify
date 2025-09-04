import { Controller } from "@hotwired/stimulus"

// Keeps chat stuck to bottom only when user is near the bottom.
// If the user scrolls up, we stop auto-scrolling and show a "Novas mensagens" button.
export default class extends Controller {
  static targets = ["anchor", "indicator"]

  connect() {
    this.sticky = true // start stuck to bottom on first load
    this._onScroll = this.onScroll.bind(this)
    this.element.addEventListener("scroll", this._onScroll, { passive: true })

    // Observe DOM changes (Turbo Streams)
    this.observer = new MutationObserver(() => this.onDomChange())
    this.observer.observe(this.element, { childList: true, subtree: true })

    // Initial scroll
    this.scrollSoon()

    // Also after Turbo renders / fonts settle, but only if sticky
    this._onTurbo = () => this.scrollSoon()
    document.addEventListener("turbo:render", this._onTurbo)
    if (document.fonts?.ready) document.fonts.ready.then(() => this.scrollSoon()).catch(() => {})
  }

  disconnect() {
    this.observer?.disconnect()
    this.element.removeEventListener("scroll", this._onScroll)
    if (this._onTurbo) document.removeEventListener("turbo:render", this._onTurbo)
  }

  // --- UI events ---
  jumpToBottom(event) {
    event?.preventDefault()
    this.sticky = true
    this.hideIndicator()
    this.scrollNow()
  }

  // --- Internals ---
  onDomChange() {
    if (this.sticky) {
      this.scrollSoon()
    } else {
      this.showIndicator()
    }
  }

  onScroll() {
    // if the user moves away from the bottom by more than 80px, disable sticky
    const dist = this.distanceFromBottom()
    const wasSticky = this.sticky
    this.sticky = dist < 80
    if (wasSticky && !this.sticky) this.showIndicator()
    if (!wasSticky && this.sticky) this.hideIndicator()
  }

  distanceFromBottom() {
    return (this.element.scrollHeight - this.element.clientHeight - this.element.scrollTop)
  }

  scrollSoon() {
    if (!this.sticky) return
    requestAnimationFrame(() => requestAnimationFrame(() => this.scrollNow()))
  }

  scrollNow() {
    if (!this.sticky) return
    // make anchor last, then jump (no smooth)
    if (this.hasAnchorTarget) this.element.appendChild(this.anchorTarget)
    this.element.scrollTop = this.element.scrollHeight
  }

  showIndicator() {
    if (this.hasIndicatorTarget) this.indicatorTarget.classList.remove("d-none")
  }
  hideIndicator() {
    if (this.hasIndicatorTarget) this.indicatorTarget.classList.add("d-none")
  }
}
