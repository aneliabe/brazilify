# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "Cleaning database..."
WorkerService.destroy_all
Service.destroy_all
Category.destroy_all
WorkerProfile.destroy_all
User.destroy_all

# categories + services
categories = {
  "Construção" => ["Pedreiro", "Pintura", "Eletricista"],
  "Tecnologia" => ["Suporte de TI", "Criação de Sites", "Designer"],
  "Beleza" => ["Cabeleireiro", "Manicure", "Maquiagem"]
}

categories.each do |cat_name, services|
  category = Category.create!(name: cat_name)
  services.each do |svc_name|
    Service.create!(name: svc_name, category: category)
  end
end

# workers
10.times do |i|
  user = User.create!(
    full_name: "Trabalhador #{i+1}",
    email: "worker#{i+1}@test.com",
    password: "123456",
    role: :worker,
    city: ["Boston", "New York", "Miami"].sample,
    country: "USA",
    avatar: "https://placehold.co/96x96"
  )

  profile = WorkerProfile.create!(
    user: user,
    cpf: "00000000#{i}",
    description: "Profissional experiente em várias áreas, pronto para ajudar!",
    rating: rand(3.5..5.0).round(2)
  )

  # assign random services
  Service.order("RANDOM()").limit(3).each do |svc|
    WorkerService.create!(worker_profile: profile, service: svc)
  end
end

puts "✅ Seed complete"
