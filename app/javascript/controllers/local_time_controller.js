import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { iso: String, label: String } // label is optional

  connect() {
    try {
      const utc = new Date(this.isoValue)                  // ISO must be in UTC
      if (isNaN(utc.getTime())) return

      const browserTZ = Intl.DateTimeFormat().resolvedOptions().timeZone || ""
      // If the server’s zone equals the browser zone, skip rendering (we’ll pass it in label).
      const serverLabel = (this.labelValue || "").trim()
      if (serverLabel && serverLabel === browserTZ) return

      const local = new Date(utc.getTime()) // browser renders in its own TZ
      const formatted = local.toLocaleString(undefined, {
        weekday: "short", year: "numeric", month: "short",
        day: "2-digit", hour: "2-digit", minute: "2-digit"
      })

      this.element.innerHTML = `
        <small class="text-muted d-block">
          ${formatted} (${browserTZ})
        </small>
      `
    } catch (_) { /* no-op */ }
  }
}
