import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["servicesContainer"]

  connect() {
    console.log("WorkerFormController connected")
    this.maxServices = 5
  }

  addServiceRow(event) {
    event.preventDefault()
    const rows = this.servicesContainerTarget.querySelectorAll(".service-row")
    if (rows.length >= this.maxServices) {
      alert("Você não pode adicionar mais de 5 serviços.")
      return
    }

    const template = document.querySelector("#worker-service-template").innerHTML
    const newId = new Date().getTime() // unique index
    const html = template.replace(/NEW_RECORD/g, newId)

    this.servicesContainerTarget.insertAdjacentHTML("beforeend", html)
  }

  removeServiceRow(event) {
    event.preventDefault()
    const row = event.target.closest(".service-row")
    if (!row) return

    const rows = this.servicesContainerTarget.querySelectorAll(".service-row")
    if (rows.length <= 1) {
      row.querySelectorAll("select, input").forEach(el => el.value = "")
      return
    }

    row.remove()
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
      })
      .catch(err => console.error("Erro ao carregar serviços:", err))
  }
}
