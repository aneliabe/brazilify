import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateServices(event) {
    const categoryId = event.target.value
    const serviceSelect = document.getElementById('service-select')

    serviceSelect.innerHTML = '<option value="">Todos</option>'

    if (!categoryId) return

    fetch(`/categories/${categoryId}/services`)
      .then(response => response.json())
      .then(services => {
        services.forEach(service => {
          const option = document.createElement('option')
          option.value = service.id
          option.textContent = service.name
          serviceSelect.appendChild(option)
        })
      })
      .catch(error => console.error('Error loading services:', error))
  }
}
