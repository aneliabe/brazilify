import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    storageKey: { type: String, default: 'brazilify_location' }
  }

  connect() {
    this.checkCacheAndRedirect()
  }

  checkCacheAndRedirect() {
    try {
      const cached = localStorage.getItem(this.storageKeyValue)
      if (!cached) return

      const data = JSON.parse(cached)
      if (data.expiry && Date.now() < data.expiry && data.city) {
        const url = new URL(window.location)
        url.searchParams.set('city', data.city)
        url.searchParams.delete('cache')
        window.location.replace(url.toString())
      }
    } catch (error) {
      console.warn('Cache redirect failed:', error)
    }
  }
}
