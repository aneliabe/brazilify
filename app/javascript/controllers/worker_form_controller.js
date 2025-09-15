import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["servicesContainer"]

  connect() {
    console.log("WorkerFormController connected")
    this.maxServices = 5

    // Ensure at least one row exists
    const rows = this.servicesContainerTarget.querySelectorAll(".service-row")
    if (rows.length === 0) this.addInitialRow()

    this.filterDuplicateServices()
  }

  addInitialRow() {
    const template = document.querySelector("#worker-service-template").innerHTML
    const newId = new Date().getTime()
    const html = template.replace(/NEW_RECORD/g, newId)
    this.servicesContainerTarget.insertAdjacentHTML("beforeend", html)
  }

  addServiceRow(event) {
    event.preventDefault()
    const rows = this.servicesContainerTarget.querySelectorAll(".service-row")
    if (rows.length >= this.maxServices) {
      alert("Você não pode adicionar mais de 5 serviços.")
      return
    }

    const template = document.querySelector("#worker-service-template").innerHTML
    const newId = new Date().getTime()
    const html = template.replace(/NEW_RECORD/g, newId)
    this.servicesContainerTarget.insertAdjacentHTML("beforeend", html)

    this.filterDuplicateServices()
  }

  removeServiceRow(event) {
    event.preventDefault()
    const row = event.target.closest(".service-row")
    if (!row) return

    const destroyField = row.querySelector('input[name*="_destroy"]')
    const isNew = row.dataset.newRecord === "true";

    if (destroyField && !isNew) {
      // Existing record: mark for destruction and hide
      destroyField.value = "1";
      row.classList.add("d-none") // hides the row visually
    } else {
      // New record: remove from DOM completely
      row.remove();
    }

    this.filterDuplicateServices()
  }

  updateServices(event) {
    const categorySelect = event.target
    const row = categorySelect.closest(".service-row")
    const serviceSelect = row.querySelector(".service-select")

    serviceSelect.innerHTML = "<option value=''>Selecione o serviço</option>"

    const categoryId = categorySelect.value
    if (!categoryId) return

    fetch(`/categories/${categoryId}/services.json`)
      .then(res => res.json())
      .then(data => {
        data.forEach(service => {
          const option = document.createElement("option")
          option.value = service.id
          option.textContent = service.name
          serviceSelect.appendChild(option)
        })

        this.filterDuplicateServices()
      })
      .catch(err => console.error("Erro ao carregar serviços:", err))
  }

  filterDuplicateServices() {
    // Gather selected service IDs (excluding hidden rows marked for destroy)
    const selectedIds = Array.from(this.servicesContainerTarget.querySelectorAll(".service-row"))
      .filter(row => row.style.display !== "none")
      .map(row => row.querySelector(".service-select").value)
      .filter(val => val !== "")

    this.servicesContainerTarget.querySelectorAll(".service-select").forEach(select => {
      const currentValue = select.value
      Array.from(select.options).forEach(option => {
        if (option.value === "") return
        option.disabled = selectedIds.includes(option.value) && option.value !== currentValue
      })
    })
  }
}



// import { Controller } from "@hotwired/stimulus"

// export default class extends Controller {
//   static targets = ["servicesContainer"]

//   connect() {
//     console.log("WorkerFormController connected")
//     this.maxServices = 5
//     this.filterDuplicateServices()
//   }

//   addServiceRow(event) {
//     event.preventDefault()
//     const rows = this.servicesContainerTarget.querySelectorAll(".service-row")
//     if (rows.length >= this.maxServices) {
//       alert("Você não pode adicionar mais de 5 serviços.")
//       return
//     }

//     const template = document.querySelector("#worker-service-template").innerHTML
//     const newId = new Date().getTime() // unique index
//     const html = template.replace(/NEW_RECORD/g, newId)

//     this.servicesContainerTarget.insertAdjacentHTML("beforeend", html)
//   }

//   removeServiceRow(event) {
//     event.preventDefault()
//     const row = event.target.closest(".service-row")
//     if (!row) return

//     const destroyField = row.querySelector('input[name*="_destroy"]')
//     const rows = this.servicesContainerTarget.querySelectorAll(".service-row")

//     if (destroyField) {
//       // Existing record: mark for destruction and hide
//       destroyField.value = "1"
//       row.style.display = "none"
//     } else {
//       // New record: just remove it from DOM
//       if (rows.length <= 1) {
//         row.querySelectorAll("select, input").forEach(el => el.value = "")
//         return
//       }
//       row.remove()
//     }
//   }

//   updateServices(event) {
//     const categorySelect = event.target
//     const row = categorySelect.closest(".service-row")
//     const serviceSelect = row.querySelector(".service-select")

//     serviceSelect.innerHTML = "<option value=''>Selecione o serviço</option>"

//     const categoryId = categorySelect.value
//     if (!categoryId) return

//     fetch(`/categories/${categoryId}/services.json`)
//       .then(res => res.json())
//       .then(data => {
//         data.forEach(service => {
//           const option = document.createElement("option")
//           option.value = service.id
//           option.textContent = service.name
//           serviceSelect.appendChild(option)
//         })

//         this.filterDuplicateServices()

//       })
//       .catch(err => console.error("Erro ao carregar serviços:", err))
//   }

//     filterDuplicateServices() {
//     // Collect all selected service IDs
//     const selectedIds = Array.from(this.servicesContainerTarget.querySelectorAll(".service-select"))
//       .map(select => select.value)
//       .filter(val => val !== "")

//     // For each select dropdown
//     this.servicesContainerTarget.querySelectorAll(".service-select").forEach(select => {
//       const currentValue = select.value
//       Array.from(select.options).forEach(option => {
//         if (option.value === "") return // keep placeholder
//         // Hide option if it's selected in another row
//         option.disabled = selectedIds.includes(option.value) && option.value !== currentValue
//       })
//     })
//   }
// }
