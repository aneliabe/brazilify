import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { Portuguese } from "flatpickr/dist/l10n/pt.js"

// Connects to data-controller="flatpickr"
export default class extends Controller {
  static values = {
    enableTime: { type: Boolean, default: true },
    linkTo: String // CSS selector of the other input (for ends_at)
  }

  connect() {
    // locale
    flatpickr.localize(Portuguese)

    const opts = {
      locale: Portuguese,
      enableTime: this.enableTimeValue,
      dateFormat: this.enableTimeValue ? "Y-m-d H:i" : "Y-m-d",
      time_24hr: true,
      minDate: "today",
      minuteIncrement: 30,

      // ✅ dynamically block past times when the selected date is today
      onReady:  (_s, _str, fp) => this.setMinTimeForToday(fp),
      onOpen:   (_s, _str, fp) => this.setMinTimeForToday(fp),
      onChange: (_s, _str, fp) => this.setMinTimeForToday(fp),
    }

    this.fp = flatpickr(this.element, opts)

    // keep your end-field linking exactly as-is
    if (this.hasLinkToValue) {
      const startInput = document.querySelector(this.linkToValue)
      if (startInput) {
        startInput.addEventListener("change", () => {
          const startDate = startInput.value && new Date(startInput.value.replace(" ", "T"))
          if (startDate && this.fp) this.fp.set("minDate", startDate)
        })
      }
    }
  }

  // ---- helpers ----
  setMinTimeForToday(fp) {
    const step = fp.config.minuteIncrement || 30
    const now = new Date()

    // which date are we validating? (selected or typed)
    const selected = fp.selectedDates[0]
    const typed = fp._input?.value ? new Date(fp._input.value.replace(" ", "T")) : null
    const target = selected || typed

    const isToday = target
      ? this.sameDate(target, now)
      : this.sameDate(fp.now || new Date(), now)

    if (isToday) {
      // round NOW up to the next step (e.g., 10:01 -> 10:30 when step=30)
      const rounded = new Date(now)
      const m = now.getMinutes()
      const extra = m % step === 0 ? 0 : (step - (m % step))
      rounded.setMinutes(m + extra, 0, 0)

      fp.set("minTime", this.hhmm(rounded))

      // if the user had picked a past time, push it forward
      if (selected && selected < rounded) fp.setDate(rounded, true)
    } else {
      fp.set("minTime", "00:00")
    }
  }

  sameDate(a, b) {
    return a && b &&
      a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate()
  }

  hhmm(d) {
    const h = String(d.getHours()).padStart(2, "0")
    const m = String(d.getMinutes()).padStart(2, "0")
    return `${h}:${m}`
  }
}
