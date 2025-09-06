import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  cleanupEnhancements() {
    // Remove any existing select-lite wrappers
    this.element.querySelectorAll('.select-lite').forEach(wrap => {
      wrap.remove()
    })

    // Restore hidden selects to visible
    this.element.querySelectorAll('.js-enhance-select.is-hidden').forEach(select => {
      select.classList.remove('is-hidden')
      delete select._selectLite
    })
  }

  connect() {
    this.cleanupEnhancements() // Clean up first
    this.enhanceSelects()
    this.setupCityToCategoryJump()
    this.setupCategoryToServiceFlow()
    this.observeSelectChanges()
  }

  enhanceSelects() {
    this.element.querySelectorAll('.js-enhance-select').forEach(select => {
      this.enhanceSelect(select)
    })
  }

  enhanceSelect(native) {
    if (!native || native.classList.contains('is-hidden')) return

    // Build wrapper
    const wrap = document.createElement('div')
    wrap.className = 'select-lite'
    if (native.dataset.fullMenu === 'true') wrap.classList.add('select-lite--full')

    const btn = document.createElement('button')
    btn.type = 'button'
    btn.className = 'select-lite__btn'

    const menu = document.createElement('ul')
    menu.className = 'select-lite__menu'
    menu.hidden = true

    // Insert after native select
    native.parentNode.insertBefore(wrap, native.nextSibling)
    wrap.appendChild(btn)
    wrap.appendChild(menu)

    function labelFor(value) {
      const opt = native.querySelector(`option[value="${CSS.escape(value)}"]`)
                || native.querySelector('option:checked')
                || native.querySelector('option')
      return opt ? opt.textContent.trim() : ''
    }

    function rebuildMenu() {
      menu.innerHTML = ''
      Array.from(native.options).forEach((opt) => {
        const li = document.createElement('li')
        li.className = 'select-lite__item'
        li.textContent = opt.textContent
        li.dataset.value = opt.value
        if (opt.selected) li.setAttribute('aria-selected', 'true')
        li.addEventListener('click', () => {
          native.value = opt.value
          Array.from(menu.children).forEach(el => el.removeAttribute('aria-selected'))
          li.setAttribute('aria-selected', 'true')
          btn.textContent = labelFor(native.value)
          native.dispatchEvent(new Event('change', { bubbles: true }))
          close()
        })
        menu.appendChild(li)
      })
      btn.textContent = labelFor(native.value || '')
    }

    function onDocClick(e) {
      if (!wrap.contains(e.target) && !wrap._programmaticOpen) {
        close()
      }
    }

    function open() {
      menu.hidden = false
      setTimeout(() => {
        document.addEventListener('click', onDocClick, { once: true })
        wrap._programmaticOpen = false
      }, 10)
    }

    function close() {
      menu.hidden = true
      wrap._programmaticOpen = false
    }

    btn.addEventListener('click', (e) => {
      e.stopPropagation()
      if (menu.hidden) {
        open()
      } else {
        close()
      }
    })

    native.addEventListener('change', () => {
      btn.textContent = labelFor(native.value || '')
      Array.from(menu.children).forEach(li => {
        li.toggleAttribute('aria-selected', li.dataset.value === native.value)
      })
    })

    const mo = new MutationObserver(rebuildMenu)
    mo.observe(native, { childList: true, subtree: true })

    native._selectLite = {
      btn,
      menu,
      open: () => {
        wrap._programmaticOpen = true
        open()
      },
      close,
      rebuildMenu
    }

    native.classList.add('is-hidden')
    rebuildMenu()
  }

  openServiceWhenOptionsChange(serviceSel) {
    if (!serviceSel || !serviceSel._selectLite) return
    let done = false
    const mo = new MutationObserver(() => {
      if (done) return
      done = true
      mo.disconnect()
      setTimeout(() => {
        serviceSel._selectLite.btn.focus()
        serviceSel._selectLite.open()
      }, 0)
    })
    mo.observe(serviceSel, { childList: true, subtree: true })
    setTimeout(() => {
      if (done) return
      mo.disconnect()
      serviceSel._selectLite.btn.focus()
      serviceSel._selectLite.open()
    }, 600)
  }

  setupCityToCategoryJump() {
    const cityInput = this.element.querySelector('input[name="city"]')
    const cityDropdown = this.element.querySelector('[data-location-hint-target="dropdown"]')
    const categorySel = this.element.querySelector('select[name="category_id"].js-enhance-select')

    if (!cityInput || !categorySel) return

    const triggerOpenCategory = () => {
      const doOpen = () => {
        if (categorySel && categorySel._selectLite) {
          setTimeout(() => {
            categorySel._selectLite.btn.focus()
            categorySel._selectLite.open()
          }, 150)
        } else {
          setTimeout(doOpen, 50)
        }
      }
      setTimeout(doOpen, 50)
    }

    cityInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        triggerOpenCategory()
      }
    })

    cityInput.addEventListener('change', (e) => {
      setTimeout(triggerOpenCategory, 100)
    })

    if (cityDropdown) {
      cityDropdown.addEventListener('mousedown', (e) => {
        setTimeout(triggerOpenCategory, 200)
      })
    }
  }

  setupCategoryToServiceFlow() {
    const categorySel = this.element.querySelector('select[name="category_id"].js-enhance-select')
    if (!categorySel) return

    categorySel.addEventListener('change', () => {
      const serviceSel = this.element.querySelector('#service-select.js-enhance-select')
      if (serviceSel) {
        this.openServiceWhenOptionsChange(serviceSel)
      }
    })
  }

  observeSelectChanges() {
    const reEnhance = new MutationObserver(() => {
      this.element.querySelectorAll('.js-enhance-select:not(.is-hidden)').forEach(select => {
        this.enhanceSelect(select)
      })
    })
    reEnhance.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    // Stimulus automatically handles cleanup
  }
}
