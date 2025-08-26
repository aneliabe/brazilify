import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categorySelect", "serviceSelect"]

  connect() {
    this.categoryServices = JSON.parse(this.element.dataset.becomeWorkerCategoryServicesValue)
  }

  updateServices() {
    const categoryId = this.categorySelectTarget.value
    const services = this.categoryServices[categoryId] || []

    this.serviceSelectTarget.innerHTML = "<option value=''>Selecione um serviço</option>"

    services.forEach(service => {
      const option = document.createElement("option")
      option.value = service.id
      option.textContent = service.name
      this.serviceSelectTarget.appendChild(option)
    })
  }
}
