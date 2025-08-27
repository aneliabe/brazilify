import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["category", "service"]

  connect() {
    console.log("WorkerFormController connected") // verify it's attached
  }

  updateServices() {
    console.log("updateServices triggered")
    console.log("Category selected:", this.categoryTarget.value)

    const categoryId = this.categoryTarget.value
    console.log("Category selected:", categoryId)

    if (!categoryId) {
      this.serviceTarget.innerHTML = '<option value="">Selecione um serviço</option>'
      return
    }

    const url = `/categories/${categoryId}/services.json`
    console.log("Fetching URL:", url)

    fetch(url)
      .then(response => response.json())
      .then(data => {
        console.log("Services fetched:", data)
        this.serviceTarget.innerHTML = '<option value="">Selecione um serviço</option>'
        data.forEach(service => {
          const option = document.createElement("option")
          option.value = service.id
          option.text = service.name
          this.serviceTarget.add(option)
        })
      })
      .catch(error => console.error("Fetch error:", error))
  }

}
