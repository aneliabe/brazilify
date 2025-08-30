(() => {
  // ---- simple settings ----
  const MAPBOX_PARAMS = {
    types: "place",
    language: "pt,en",
    // country: "BR,IE,PT,US,GB",
    limit: 7
  };
  const DEBOUNCE_MS = 250;
  const MIN_CHARS = 2;
  const ENDPOINT = "https://api.mapbox.com/search/geocode/v6/forward";



  function buildUrl(q, token) {
    const params = new URLSearchParams({ q, access_token: token });
    for (const [k, v] of Object.entries(MAPBOX_PARAMS)) if (v) params.set(k, v);
    return `${ENDPOINT}?${params.toString()}`;
  }

  function setupCityAutocomplete(input, datalist, token) {
    window.setupCityAutocomplete = setupCityAutocomplete;
    if (!input || !datalist || !token) return;
    if (input.dataset.cityAutocompleteBound === "true") return;
    input.dataset.cityAutocompleteBound = "true";


    let t = null;
    let lastController = null;

    let suppressUntil = 0;
    let lastQueryShown = "";

    function closeDatalist() {
      datalist.innerHTML = "";
      // use the actual datalist id, not a hard-coded string
      const listId = datalist.id;
      input.setAttribute("list", "");
      setTimeout(() => input.setAttribute("list", listId), 0);

      suppressUntil = Date.now() + 400; // cooldown
      // allow same query to rebuild after close
      lastQueryShown = "";
    }

    input.addEventListener("change", closeDatalist);
    input.addEventListener("blur",   closeDatalist);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === "Tab" || e.key === "Escape") closeDatalist();
    });

    input.addEventListener("input", () => {
      clearTimeout(t);
      const q = input.value.trim();

      if (Date.now() < suppressUntil) return;
      if (q.length < MIN_CHARS) { closeDatalist(); return; }

      t = setTimeout(async () => {
        if (Date.now() < suppressUntil || input !== document.activeElement) return;
        if (q === lastQueryShown) return;

        if (lastController) lastController.abort();
        lastController = new AbortController();

        try {
          const res = await fetch(buildUrl(q, token), { signal: lastController.signal });
          if (!res.ok) {
            console.error("Mapbox HTTP error", res.status, await res.text());
            return;
          }
          const data = await res.json();

          datalist.innerHTML = "";
          const features = Array.isArray(data.features) ? data.features : [];
          if (features.length === 0) { closeDatalist(); return; }

          lastQueryShown = q;

const seen = new Set();
features.forEach(f => {
  const props   = f.properties || {};
  const name    = (props.name || "").trim();
  const country = (props.context?.country?.country_code || "").toUpperCase();
  if (!name) return;

  // label: "Cidade, PAÍS" (se país vier vazio, mostra só a cidade)
  const label = country ? `${name}, ${country}` : name;
  // dedupe inclui país para não colidir "Dublin, IE" com "Dublin, US"
  const key   = `${name.toLowerCase()}||${country}`;

  if (seen.has(key)) return;
  seen.add(key);

  const opt = document.createElement("option");
  opt.value = label;
  datalist.appendChild(opt);
});
        } catch (e) {
          if (e.name !== "AbortError") console.error("Fetch failed:", e);
        }
      }, DEBOUNCE_MS);
    });
  }

  function init() {
    const token    = document.querySelector('meta[name="mapbox-token"]')?.content;
    const input    = document.getElementById("city-input");
    const datalist = document.getElementById("city-suggestions");
    if (!token) console.warn("MAPBOX_PUBLIC_TOKEN is missing");
    setupCityAutocomplete(input, datalist, token);
  }

  document.addEventListener("turbo:load", init);
  document.addEventListener("DOMContentLoaded", init);

})();
