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
    if (rows.length >= this.maxServices) return

    const template = rows[0].cloneNode(true)
    template.querySelectorAll("select").forEach(select => select.value = "")
    this.servicesContainerTarget.appendChild(template)
  }

  removeServiceRow(event) {
    event.preventDefault()
    const row = event.target.closest(".service-row")
    if (!row) return

    const rows = this.servicesContainerTarget.querySelectorAll(".service-row")
    if (rows.length <= 1) {
      row.querySelectorAll("select").forEach(select => select.value = "")
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
