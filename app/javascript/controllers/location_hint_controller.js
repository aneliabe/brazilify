import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "wrap", "status", "lat", "lng", "datalist", "country"]
  static values = {
    token: String,
    showNearby: { type: Boolean, default: true },
    enableCache: { type: Boolean, default: false }  // You already changed this
  }

  static FWD = "https://api.mapbox.com/search/geocode/v6/forward"
  static REV = "https://api.mapbox.com/search/geocode/v6/reverse"
  static PARAMS = { types: "place", language: "pt,en", limit: "7", proximity: "ip", country: "IE,PT,GB,US" }

  connect() {
    this.timeout = null
    this.cachedPosition = null
    this.cacheExpiry = null
    this.STORAGE_KEY = 'brazilify_location'
    this.CACHE_DURATION = 30 * 60 * 1000 // 30 minutes

    this.nearbyRow = {
      type: "nearby",
      icon: '<i class="fa-solid fa-location-crosshairs location-icon nearby me-2"></i>',
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
          // this.flashStatus("Localização salva carregada", 1000)
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

  // NEW: Load nearby major cities based on IP location
  async loadNearbyCities() {
    try {
      const response = await fetch("/location_hint")
      if (!response.ok) return []

      const data = await response.json()

      // Get major cities based on detected location
      const nearbyCities = this.getMajorCitiesFor(data.city, data.ip)

      return nearbyCities.map(city => ({
        type: "major_city",
        icon: '<i class="fa-solid fa-city location-icon major me-2"></i>',
        label: city.name,
        lat: city.lat,
        lng: city.lng,
        country: city.country_code
      }))
    } catch {
      // Fallback to Ireland cities if IP detection fails
      return this.getDefaultMajorCities()
    }
  }

  // NEW: Define major cities database based on user's region
  getMajorCitiesFor(detectedCity, clientIp) {
    const cityDatabase = {
      // Ireland
      'IE': [
        { name: "Dublin", lat: 53.3498, lng: -6.2603, country: "Ireland", country_code: "IE" },
        { name: "Cork", lat: 51.8985, lng: -8.4756, country: "Ireland", country_code: "IE" },
        { name: "Galway", lat: 53.2707, lng: -9.0568, country: "Ireland", country_code: "IE" },
        { name: "Limerick", lat: 52.6638, lng: -8.6267, country: "Ireland", country_code: "IE" },
        { name: "Waterford", lat: 52.2583, lng: -7.1119, country: "Ireland", country_code: "IE" }
      ],
      // United Kingdom
      'GB': [
        { name: "London", lat: 51.5074, lng: -0.1278, country: "United Kingdom", country_code: "GB" },
        { name: "Manchester", lat: 53.4808, lng: -2.2426, country: "United Kingdom", country_code: "GB" },
        { name: "Birmingham", lat: 52.4862, lng: -1.8904, country: "United Kingdom", country_code: "GB" },
        { name: "Edinburgh", lat: 55.9533, lng: -3.1883, country: "United Kingdom", country_code: "GB" },
        { name: "Glasgow", lat: 55.8642, lng: -4.2518, country: "United Kingdom", country_code: "GB" }
      ],
      // United States
      'US': [
        { name: "New York", lat: 40.7128, lng: -74.0060, country: "United States", country_code: "US" },
        { name: "Los Angeles", lat: 34.0522, lng: -118.2437, country: "United States", country_code: "US" },
        { name: "Chicago", lat: 41.8781, lng: -87.6298, country: "United States", country_code: "US" },
        { name: "Miami", lat: 25.7617, lng: -80.1918, country: "United States", country_code: "US" },
        { name: "Boston", lat: 42.3601, lng: -71.0589, country: "United States", country_code: "US" }
      ],
      // Portugal
      'PT': [
        { name: "Lisbon", lat: 38.7223, lng: -9.1393, country: "Portugal", country_code: "PT" },
        { name: "Porto", lat: 41.1579, lng: -8.6291, country: "Portugal", country_code: "PT" },
        { name: "Braga", lat: 41.5518, lng: -8.4229, country: "Portugal", country_code: "PT" },
        { name: "Coimbra", lat: 40.2033, lng: -8.4103, country: "Portugal", country_code: "PT" }
      ]
    }

    // Detect country based on city name or IP patterns
    let countryCode = 'IE' // Default to Ireland

    if (detectedCity) {
      const city = detectedCity.toLowerCase()
      if (city.includes('dublin') || city.includes('cork') || city.includes('galway') || city.includes('ireland')) {
        countryCode = 'IE'
      } else if (city.includes('london') || city.includes('manchester') || city.includes('birmingham') || city.includes('uk')) {
        countryCode = 'GB'
      } else if (city.includes('new york') || city.includes('los angeles') || city.includes('chicago') || city.includes('miami')) {
        countryCode = 'US'
      } else if (city.includes('lisbon') || city.includes('porto') || city.includes('portugal')) {
        countryCode = 'PT'
      }
    }

    return cityDatabase[countryCode] || cityDatabase['IE']
  }

  // NEW: Fallback major cities (Ireland default)
  getDefaultMajorCities() {
    return [
      { name: "Dublin", lat: 53.3498, lng: -6.2603, country: "Ireland", country_code: "IE" },
      { name: "Cork", lat: 51.8985, lng: -8.4756, country: "Ireland", country_code: "IE" },
      { name: "Galway", lat: 53.2707, lng: -9.0568, country: "Ireland", country_code: "IE" },
      { name: "Limerick", lat: 52.6638, lng: -8.6267, country: "Ireland", country_code: "IE" }
    ].map(city => ({
      type: "major_city",
      icon: '<i class="fa-solid fa-location-dot me-2" style="color: #2c7a7b;"></i>', // Using your brand color
      label: city.name,
      lat: city.lat,
      lng: city.lng,
      country: city.country_code
    }))
  }

  // ENHANCED: Modified bindEvents to include major cities
  bindEvents() {
    // Keep focus in input when interacting with dropdown
    this.dropdownTarget.addEventListener("mousedown", (e) => e.preventDefault(), true)

    // ENHANCED: Show nearby + major cities on focus/click
    if (this.showNearbyValue) {
      this.inputTarget.addEventListener("focus", async () => {
        const nearbyCities = await this.loadNearbyCities()
        const allOptions = [this.nearbyRow, ...nearbyCities]
        this.openDropdown(allOptions)
      })

      this.inputTarget.addEventListener("click", async () => {
        const nearbyCities = await this.loadNearbyCities()
        const allOptions = [this.nearbyRow, ...nearbyCities]
        this.openDropdown(allOptions)
      })
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
      // ENHANCED: Show nearby + major cities when input is empty
      if (this.showNearbyValue) {
        this.loadNearbyCities().then(nearbyCities => {
          const allOptions = [this.nearbyRow, ...nearbyCities]
          this.openDropdown(allOptions)
        })
      } else {
        this.closeDropdown()
      }
      return
    }

    this.timeout = setTimeout(async () => {
      const items = this.tokenValue ? await this.fetchCities(q, this.tokenValue) : []
      const rows = items.map(c => ({
        type: "city",
        icon: '<i class="fa-regular fa-building location-icon search me-2"></i>',
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

  // ENHANCED: Handle major city clicks
  async handleDropdownClick(e) {
    const btn = e.target.closest("button.dropdown-item")
    if (!btn) return

    const type = btn.dataset.type

    if (type === "nearby") {
      await this.doNearby()
      this.closeDropdown()
      return
    }

    // Handle both regular cities and major cities
    if (type === "major_city" || type === "city") {
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
      return
    }
  }

  async doNearby() {
    // Check if we have a recent cached position (5 minutes)
    if (this.cachedPosition && this.cacheExpiry && Date.now() < this.cacheExpiry) {
      this.flashStatus("Usando localização salva")
      await this.usePosition(this.cachedPosition)
      return
    }

    if (navigator.geolocation) {
      // this.flashStatus("Localizando…", 0)
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
            // this.flashStatus("Detectado")
          } catch {
            // this.flashStatus("Sem localização")
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
        // this.flashStatus("Detectado")
      } catch {
        // this.flashStatus("Sem localização")
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
      // this.flashStatus("Detectado")
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
      const lat = f?.properties?.coordinates?.latitude ?? f?.center?.[1]
      const lng = f?.properties?.coordinates?.longitude ?? f?.center?.[0]
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
  }

  populateCountryField(locationText) {
    if (!this.hasCountryTarget) {
      return
    }

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
        this.countryTarget.value = value
        return
      }
    }
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
