categories = [
  "Construção",
  "Tecnologia",
  "Beleza / Estética",
  "Serviços Automotivos",
  "Manutenção Residencial",
  "Saúde e Bem-estar",
  "Educação",
  "Transporte e Logística",
  "Serviços Domésticos",
  "Eventos",
  "Animais de Estimação",
  "Administração / Negócios",
  "Arte e Artesanato"
]

categories.each do |name|
  Category.find_or_create_by!(name: name)
end

puts "✅ Categories seeded"
