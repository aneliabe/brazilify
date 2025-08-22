class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @popular_services = [
      { name: "Limpeza Doméstica" },
      { name: "Beleza" },
      { name: "Saúde" },
      { name: "Pet Sitter" },
      { name: "Serviços Automotivos" },
      { name: "Manutenção residencial" }
    ]

    @best_workers = [
      { name: "João", role: "Eletricista", city: "Boston", dist: "500m", rating: 4.9, avatar: nil },
      { name: "Maria", role: "Manicure", city: "Miami", dist: "1.2km", rating: 4.8, avatar: nil },
      { name: "Carlos", role: "Mecânico", city: "NYC", dist: "800m", rating: 5.0, avatar: nil },
      { name: "Ana", role: "Limpeza", city: "LA", dist: "2km", rating: 4.7, avatar: nil },
      { name: "Paulo", role: "Pintor", city: "SF", dist: "1km", rating: 4.9, avatar: nil },
      { name: "Luiza", role: "Pet Sitter", city: "Chicago", dist: "700m", rating: 4.8, avatar: nil }
    ]
  end

  def search
    @city = params[:city].to_s.strip
    @workers = Worker
              .where("LOWER(city) LIKE ?", "%#{@city.downcase}%")
              .includes(:services)
  end
end
