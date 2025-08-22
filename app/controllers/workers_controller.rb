class WorkersController < ApplicationController
  def show
    # TEMP: mock until DB is ready
    @worker = {
      id: params[:id], name: "Maria Silva", role: "Limpeza Doméstica",
      city: "Boston, US", rating: 4.9, reviews: 32,
      avatar: nil, description: "Profissional pontual, materiais próprios.",
      services: ["Limpeza leve", "Faxina pesada", "Organização"]
    }
  end
end
