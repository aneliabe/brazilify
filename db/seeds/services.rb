services_by_category = {
  "Construção" => ["Pedreiro", "Pintura", "Eletricista"],

  "Tecnologia" => ["Suporte de TI", "Criação de Sites", "Designer"],

  "Beleza / Estética" => [
    "Cabeleireiro", "Manicure", "Maquiagem",
    "Corte feminino/masculino/infantil",
    "Escova/chapinha/babyliss",
    "Coloração e mechas",
    "Progressiva/alisamento",
    "Hidratação e tratamentos capilares",
    "Alongamento de unhas (gel, fibra, acrílico)",
    "Nail art personalizada",
    "Limpeza de pele",
    "Design de sobrancelhas",
    "Micropigmentação",
    "Extensão de cílios",
    "Drenagem linfática",
    "Massagem modeladora",
    "Depilação (cera, laser, linha)",
    "Bronzeamento artificial",
    "Tratamentos para celulite/estrias",
    "Massagem relaxante",
    "Aromaterapia",
    "Reflexologia",
    "Spa day completo"
  ],

  # ... (keep the rest of your hash here, unchanged) ...
}

services_by_category.each do |category_name, services|
  category = Category.find_or_create_by!(name: category_name)

  services.each do |service_name|
    Service.find_or_create_by!(name: service_name, category: category)
  end
end

puts "✅ Services seeded"
