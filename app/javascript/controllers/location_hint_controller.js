import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "wrap", "status", "lat", "lng", "datalist", "country"]
static values = { token: String, showNearby: { type: Boolean, default: true }, enableCache: { type: Boolean, default: true } }

  static FWD = "https://api.mapbox.com/search/geocode/v6/forward"
  static REV = "https://api.mapbox.com/search/geocode/v6/reverse"
  static PARAMS = { types: "place", language: "pt,en", limit: "7", proximity: "ip", country: "IE,PT,BR,GB,US" }


  connect() {
    this.timeout = null
    this.cachedPosition = null
    this.cacheExpiry = null
    this.STORAGE_KEY = 'brazilify_location'
    this.CACHE_DURATION = 30 * 60 * 1000 // 30 minutes

    this.nearbyRow = {
      type: "nearby",
      icon: '<i class="fa-solid fa-location-crosshairs me-2"></i>',
      label: "Nearby",
      // sub: "Use sua localização atual"
    }

    // Load saved location on page load
    this.loadSavedLocation()
    this.bindEvents()

    // Quietly preload location in background
    this.preloadLocation()
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  loadSavedLocation() {
  // Skip loading saved location if cache is disabled
  if (!this.enableCacheValue) return

  try {
    const saved = localStorage.getItem(this.STORAGE_KEY)
    if (!saved) return

    const data = JSON.parse(saved)
    const now = Date.now()

    // Check if data is still valid (within 30 minutes)
    if (data.expiry && now < data.expiry) {
      this.inputTarget.value = data.city || ''
      if (this.hasLatTarget && data.lat) this.latTarget.value = data.lat
      if (this.hasLngTarget && data.lng) this.lngTarget.value = data.lng
      if (this.hasCountryTarget && data.country) this.countryTarget.value = data.country

      // Show subtle indicator that we loaded saved location
      if (data.city) {
        this.flashStatus("Localização salva carregada", 1000)
      }
    } else {
      // Data expired, remove it
      localStorage.removeItem(this.STORAGE_KEY)
    }
  } catch (e) {
    // Silent fail if localStorage isn't available
    console.warn('Could not load saved location:', e)
  }
}

 saveLocation(city, lat, lng, country = null) {
  // Skip saving if cache is disabled
  if (!this.enableCacheValue) return

  try {
    const data = {
      city,
      lat,
      lng,
      country,
      expiry: Date.now() + this.CACHE_DURATION,
      timestamp: Date.now()
    }
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(data))
  } catch (e) {
    // Silent fail if localStorage isn't available (private browsing, etc.)
    console.warn('Could not save location:', e)
  }
}

  preloadLocation() {
    // Only if we don't have recent cached data
    const saved = localStorage.getItem(this.STORAGE_KEY)
    if (saved) {
      try {
        const data = JSON.parse(saved)
        if (data.expiry && Date.now() < data.expiry) return // Still fresh
      } catch (e) {}
    }

    // Silently get location for next time
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(pos => {
        this.cachedPosition = pos
        this.cacheExpiry = Date.now() + (5 * 60 * 1000)
      }, () => {
        // Silent fail
      }, {
        enableHighAccuracy: false,
        timeout: 3000,
        maximumAge: 300000
      })
    }
  }

  bindEvents() {
  // Keep focus in input when interacting with dropdown
  this.dropdownTarget.addEventListener("mousedown", (e) => e.preventDefault(), true)

  // Only bind focus/click events to show dropdown if nearby is enabled
  if (this.showNearbyValue) {
    this.inputTarget.addEventListener("focus", () => this.openDropdown([this.nearbyRow]))
    this.inputTarget.addEventListener("click", () => this.openDropdown([this.nearbyRow]))
  }

  // Typing: Nearby + Mapbox results
  this.inputTarget.addEventListener("input", () => this.handleInput())

  // Click on dropdown item
  this.dropdownTarget.addEventListener("click", (e) => this.handleDropdownClick(e))

  // Close on Escape
  this.inputTarget.addEventListener("keydown", (e) => {
    if (e.key === "Escape") this.closeDropdown()
  })

  // Close when focus leaves wrapper
  document.addEventListener("focusin", (e) => {
    if (!this.wrapTarget.contains(e.target)) this.closeDropdown()
  })

  // Close before Turbo cache
  document.addEventListener("turbo:before-cache", () => this.closeDropdown())
}

  handleInput() {
  const q = this.inputTarget.value.trim()
  clearTimeout(this.timeout)

  if (!q) {
    // Only show dropdown if nearby is enabled, otherwise close it
    if (this.showNearbyValue) {
      this.openDropdown([this.nearbyRow])
    } else {
      this.closeDropdown()
    }
    return
  }

  this.timeout = setTimeout(async () => {
    const items = this.tokenValue ? await this.fetchCities(q, this.tokenValue) : []
    const rows = items.map(c => ({
      type: "city",
      icon: '<i class="fa-regular fa-building me-2"></i>',
      label: c.label,
      sub: c.sub,
      lat: c.lat,
      lng: c.lng,
      country: c.country
    }))

    // Add nearby button only if enabled
    const finalRows = this.showNearbyValue ? [this.nearbyRow, ...rows] : rows
    this.openDropdown(finalRows)
  }, 200)
}

  async handleDropdownClick(e) {
    const btn = e.target.closest("button.dropdown-item")
    if (!btn) return

    const type = btn.dataset.type

    if (type === "nearby") {
      await this.doNearby()
      this.closeDropdown()
      return
    }

    const label = btn.querySelector("strong")?.textContent?.trim()
    const fullText = btn.querySelector("small")?.textContent?.trim() || ""
    const lat = btn.dataset.lat
    const lng = btn.dataset.lng
    const country = btn.dataset.country

    if (label) this.inputTarget.value = label
    if (lat && this.hasLatTarget) this.latTarget.value = lat
    if (lng && this.hasLngTarget) this.lngTarget.value = lng

    // Set country field
    if (country) {
      this.setCountryDirect(country)
    } else {
      this.populateCountryField(fullText || label)
    }

    // Save location data including country
    const countryValue = this.hasCountryTarget ? this.countryTarget.value : null
    if (label && lat && lng) {
      this.saveLocation(label, lat, lng, countryValue)
    }

    this.closeDropdown()
  }

  async doNearby() {
    // Check if we have a recent cached position (5 minutes)
    if (this.cachedPosition && this.cacheExpiry && Date.now() < this.cacheExpiry) {
      this.flashStatus("Usando localização salva")
      await this.usePosition(this.cachedPosition)
      return
    }

    if (navigator.geolocation) {
      this.flashStatus("Localizando…", 0)
      return new Promise(resolve => {
        navigator.geolocation.getCurrentPosition(async pos => {
          // Cache the position for 5 minutes
          this.cachedPosition = pos
          this.cacheExpiry = Date.now() + (5 * 60 * 1000)

          await this.usePosition(pos)
          resolve()
        }, async () => {
          try {
            const hint = await fetch("/location_hint").then(r => r.ok ? r.json() : null)
            if (hint?.city) this.inputTarget.value = hint.city
            if (this.hasLatTarget && hint?.lat) this.latTarget.value = hint.lat
            if (this.hasLngTarget && hint?.lng) this.lngTarget.value = hint.lng
            this.flashStatus("Detectado")
          } catch {
            this.flashStatus("Sem localização")
          }
          resolve()
        }, {
          enableHighAccuracy: false,
          timeout: 5000,
          maximumAge: 300000
        })
      })
    } else {
      try {
        const hint = await fetch("/location_hint").then(r => r.ok ? r.json() : null)
        if (hint?.city) this.inputTarget.value = hint.city
        if (this.hasLatTarget && hint?.lat) this.latTarget.value = hint.lat
        if (this.hasLngTarget && hint?.lng) this.lngTarget.value = hint.lng
        this.flashStatus("Detectado")
      } catch {
        this.flashStatus("Sem localização")
      }
    }
  }

  async usePosition(pos) {
    try {
      const lat = pos.coords.latitude
      const lng = pos.coords.longitude
      if (this.hasLatTarget) this.latTarget.value = lat
      if (this.hasLngTarget) this.lngTarget.value = lng

      const c = await this.reverseToCity(lat, lng, this.tokenValue)
      if (c.label) {
        this.inputTarget.value = c.label
        // Try to get country from reverse geocoding
        await this.setCountryFromCoordinates(lat, lng)
        // Save to localStorage for next time
        const countryValue = this.hasCountryTarget ? this.countryTarget.value : null
        this.saveLocation(c.label, lat, lng, countryValue)
      }
      this.flashStatus("Detectado")
    } catch {
      this.flashStatus("Falha ao detectar")
    }
  }

async fetchCities(q, token) {
  if (!token) {
    console.warn('Mapbox token is missing')
    return []
  }

  const u = new URL(this.constructor.FWD)
  u.searchParams.set("q", q)
  Object.entries(this.constructor.PARAMS).forEach(([k, v]) => u.searchParams.set(k, v))
  u.searchParams.set("access_token", token)

  try {
    const r = await fetch(u)
    if (!r.ok) return []
    const j = await r.json()
    return (j.features || []).map(f => ({
      label: f?.properties?.name || f?.text || f?.place_name || "",
      sub: f?.place_name || f?.properties?.full_address || "",
      lat: f?.properties?.coordinates?.latitude ?? f?.center?.[1],
      lng: f?.properties?.coordinates?.longitude ?? f?.center?.[0],
      country: f?.properties?.context?.country?.name || f?.properties?.context?.country?.country_code || ""
    }))
  } catch {
    return []
  }
}

  fixIrishCities(cityName) {
  const corkSuburbs = ['Douglas', 'Blackrock', 'Ballincollig', 'Carrigaline', 'Mahon', 'Glanmire']
  const dublinSuburbs = ['Dun Laoghaire', 'Blackrock', 'Sandyford', 'Tallaght']

  if (corkSuburbs.includes(cityName)) return 'Cork'
  if (dublinSuburbs.includes(cityName)) return 'Dublin'

  return cityName
}

async reverseToCity(lat, lng, token) {
  const u = new URL(this.constructor.REV)
  u.searchParams.set("latitude", lat)
  u.searchParams.set("longitude", lng)
  u.searchParams.set("types", "place")
  u.searchParams.set("limit", "1")
  u.searchParams.set("language", "pt,en")
  u.searchParams.set("access_token", token)

  try {
    const j = await fetch(u).then(x => x.json())
    const f = j.features?.[0]
    const cityName = f?.properties?.name || f?.place_name || ""

    // Fix known Irish suburbs
    const correctedCity = this.fixIrishCities(cityName)

    return { label: correctedCity, lat, lng }
  } catch {
    return { label: "", lat, lng }
  }
}

  openDropdown(rows) {
    this.dropdownTarget.innerHTML = rows.map(r => `
      <button type="button"
              class="dropdown-item d-flex align-items-center"
              data-type="${r.type}"
              ${r.lat != null ? `data-lat="${r.lat}"` : ""}
              ${r.lng != null ? `data-lng="${r.lng}"` : ""}
              ${r.country ? `data-country="${r.country}"` : ""}>
        ${r.icon || ""}
        <span>
          <strong>${r.label}</strong>
          ${r.sub ? `<small class="text-muted ms-2">${r.sub}</small>` : ""}
        </span>
      </button>
    `).join("")

    this.dropdownTarget.classList.add("show")

    // Pause native datalist
    if (this.hasDatalistTarget && !this.inputTarget._savedListAttr) {
      this.inputTarget._savedListAttr = this.inputTarget.getAttribute("list")
      if (this.inputTarget._savedListAttr) this.inputTarget.removeAttribute("list")
    }
  }

  closeDropdown() {
    this.dropdownTarget.classList.remove("show")
    this.dropdownTarget.innerHTML = ""

    // Restore native datalist
    if (this.hasDatalistTarget && this.inputTarget._savedListAttr) {
      this.inputTarget.setAttribute("list", this.inputTarget._savedListAttr)
      this.inputTarget._savedListAttr = null
    }
  }

  flashStatus(msg, ms = 1800) {
    if (!this.hasStatusTarget) return

    if (!msg) {
      this.statusTarget.textContent = ""
      this.statusTarget.classList.add("d-none")
      return
    }

    this.statusTarget.textContent = msg
    this.statusTarget.classList.remove("d-none")
    if (ms) setTimeout(() => this.statusTarget.classList.add("d-none"), ms)
  }

  setCountryDirect(country) {
    if (!this.hasCountryTarget) return

    // console.log("Setting country directly:", country)

    const countryMappings = {
      'IE': 'Ireland',
      'Ireland': 'Ireland',
      'US': 'United States',
      'USA': 'United States',
      'United States': 'United States',
      'BR': 'Brazil',
      'Brazil': 'Brazil',
      'Brasil': 'Brazil',
      'PT': 'Portugal',
      'Portugal': 'Portugal',
      'GB': 'United Kingdom',
      'UK': 'United Kingdom',
      'United Kingdom': 'United Kingdom'
    }

    this.countryTarget.value = countryMappings[country] || country
    // console.log("Country field set to:", this.countryTarget.value)
  }

  populateCountryField(locationText) {
    if (!this.hasCountryTarget) {
      // console.log("No country target found")
      return
    }

    // console.log("Parsing country from location text:", locationText)

    const countryMappings = {
      'Ireland': 'Ireland',
      'USA': 'United States',
      'United States': 'United States',
      'Brazil': 'Brazil',
      'Brasil': 'Brazil',
      'Portugal': 'Portugal',
      'United Kingdom': 'United Kingdom',
      'UK': 'United Kingdom'
    }

    for (const [key, value] of Object.entries(countryMappings)) {
      if (locationText.includes(key)) {
        // console.log(`Found country match: ${key} -> ${value}`)
        this.countryTarget.value = value
        return
      }
    }

    // console.log("No country match found in:", locationText)
  }

  async setCountryFromCoordinates(lat, lng) {
    if (!this.hasCountryTarget) return

    try {
      const u = new URL(this.constructor.REV)
      u.searchParams.set("latitude", lat)
      u.searchParams.set("longitude", lng)
      u.searchParams.set("types", "country")
      u.searchParams.set("limit", "1")
      u.searchParams.set("access_token", this.tokenValue)

      const response = await fetch(u)
      const data = await response.json()
      const country = data.features?.[0]?.properties?.name ||
                    data.features?.[0]?.properties?.country_code?.toUpperCase()

      if (country) {
        this.setCountryDirect(country)
      }
    } catch (e) {
      console.warn('Could not extract country from coordinates:', e)
    }
  }
}
