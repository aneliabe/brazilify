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
    // localize first (this line is safe even if already localized)
    flatpickr.localize(Portuguese)

    const opts = {
      locale: Portuguese,
      enableTime: this.enableTimeValue,
      dateFormat: this.enableTimeValue ? "Y-m-d H:i" : "Y-m-d",
      time_24hr: true,
      minDate: "today",
      minuteIncrement: 30
    }

    this.fp = flatpickr(this.element, opts)

    // if this is the end field and we have a start field to link to:
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
}
